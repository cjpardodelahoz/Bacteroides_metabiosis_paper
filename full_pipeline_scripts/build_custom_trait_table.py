#!/usr/bin/env python3
"""Build the custom PICRUSt2 trait table from dbCAN + SignalP6 annotations of
the PICRUSt2 bac_ref reference genomes.

By default, for each genome and each gene sitting in a CGC with a predicted
signal peptide, we take the distinct set of digestive (GH/PL/CE) families the
gene's Gene Annotation carries (deduping
repeated same-family domains, keeping genuinely different families). For each
such family we try to resolve a specific EC using the gene's own dbCAN-sub
(eCAMI) domain hits for that family:
  - no EC candidates at all             -> "<family>_unresolved"
  - exactly one distinct EC candidate   -> "<family>_<EC>" (always resolved)
  - >=2 distinct EC candidates          -> resolved to the top-support EC only
                                           if top/total >= 0.70 AND
                                           total >= 5; else "<family>_unresolved"

Genes are NOT filtered on dbCAN's `Gene Type` column. For genes carrying both
a CAZyme and a transporter/TF annotation, dbCAN collapses the annotations with
`'+'.join(set(...))` and then takes the first '|' field as Gene Type, so the
label of a fused gene is decided by Python set ordering (empirically a ~50/50
coin flip across the reference set) rather than by biology. Selecting on the
digestive family found in the annotation itself is therefore both broader and
more deterministic.

No CGC-level GT exclusion: a GT gene elsewhere in a CGC does not disqualify
a digestive CAZyme gene in the same cluster (GT genes simply have no
digestive family themselves, so they never contribute).

Output: one row per PICRUSt2 bac_ref genome accession (all 26,868, zero-filled
for genomes with no CGC data), one column per "<family>_<EC>" or
"<family>_unresolved" trait. The optional ``all_digestive`` mode includes
both signal-peptide-positive and signal-peptide-negative genes while retaining
the header of the secreted table (passed as the reference table).

Usage:
  python3 build_custom_trait_table.py GENOME_LIST OUT_TSV [secreted|all_digestive] [REFERENCE_TABLE]
"""
import csv
import os
import re
import sys

PUL_DIR = "analyses/picrust_custom_traits/bacref_pul_prediction"
GENOME_LIST = "analyses/picrust_custom_traits/bacteria_genomes.txt"
OUT_TSV = "analyses/picrust_custom_traits/custom_trait_table_secreted.tsv"

DIGESTIVE_RE = re.compile(r"^(GH|PL|CE)\d+")
RATIO_THRESHOLD = 0.70
MIN_MULTI_SUPPORT = 5


def load_genome_list(path):
    with open(path) as f:
        return [line.strip() for line in f if line.strip()]


def load_signalp_positive(path):
    """Return the set of protein IDs with a predicted signal peptide
    (any SignalP6 call other than OTHER). Missing file -> empty set."""
    positive = set()
    if not os.path.isfile(path):
        return positive
    with open(path) as f:
        header = f.readline()
        if not header.startswith("# ID"):
            # first line is the "# SignalP-6.0 ..." comment; read the real header
            header = f.readline()
        cols = header.rstrip("\n").split("\t")
        try:
            id_idx = cols.index("# ID")
        except ValueError:
            id_idx = 0
        pred_idx = cols.index("Prediction") if "Prediction" in cols else 1
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) <= max(id_idx, pred_idx):
                continue
            full_id = parts[id_idx]
            prediction = parts[pred_idx]
            if prediction == "OTHER":
                continue
            # full_id format: contig|CGC#|protein_id|GeneType|Annotation
            fields = full_id.split("|")
            if len(fields) >= 3:
                protein_id = fields[2]
                positive.add(protein_id)
    return positive


def load_dbcan_sub(path):
    """Return dict: protein_id -> list of (subfamily_name, ec_field_raw)."""
    by_protein = {}
    if not os.path.isfile(path):
        return by_protein
    with open(path) as f:
        next(f, None)  # header: Subfam Name / Subfam Composition / Subfam EC / ...
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 6:
                continue
            subfamily_name = parts[0]
            ec_field = parts[2]
            protein_id = parts[5]
            by_protein.setdefault(protein_id, []).append((subfamily_name, ec_field))
    return by_protein


def parse_ec_field(ec_field):
    """Parse 'EC:count|EC:count|...' into [(ec, count), ...]. '-' -> []."""
    if ec_field in ("-", ""):
        return []
    pairs = []
    for item in ec_field.split("|"):
        if ":" not in item:
            continue
        ec, cnt = item.rsplit(":", 1)
        try:
            pairs.append((ec, int(cnt)))
        except ValueError:
            continue
    return pairs


def gene_domain_tokens(gene_annotation):
    """Split a Gene Annotation string into raw domain tokens, dropping the
    leading type field and truncating each token at its first '+' (which marks
    a fused annotation boundary such as '...+CAZyme' or '+TC|8.A.9.1.3')."""
    fields = gene_annotation.split("|")[1:]
    return [field.split("+")[0] for field in fields]


def resolve_family_ec(candidates):
    """candidates: list of (ec, count) pairs (already merged/summed by ec
    across all of a gene's domain tokens for one family).
    Returns a column-name suffix: an EC string, or 'unresolved'."""
    if not candidates:
        return "unresolved"
    if len(candidates) == 1:
        return candidates[0][0]
    total = sum(c for _, c in candidates)
    top_ec, top_count = max(candidates, key=lambda x: x[1])
    if total >= MIN_MULTI_SUPPORT and (top_count / total) >= RATIO_THRESHOLD:
        return top_ec
    return "unresolved"


def process_genome(accession, require_signalp=True):
    """Return dict: column_name -> count, for one genome."""
    genome_dir = os.path.join(PUL_DIR, accession)
    cgc_path = os.path.join(genome_dir, "cgc_standard_out.tsv")
    if not os.path.isfile(cgc_path):
        return {}

    signalp_positive = set()
    if require_signalp:
        signalp_path = os.path.join(genome_dir, "signalp", "prediction_results.txt")
        signalp_positive = load_signalp_positive(signalp_path)
        if not signalp_positive:
            return {}

    dbcan_sub_path = os.path.join(genome_dir, "dbCANsub_hmm_results.tsv")
    dbcan_sub = load_dbcan_sub(dbcan_sub_path)

    counts = {}
    with open(cgc_path) as f:
        header = f.readline().rstrip("\n").split("\t")
        try:
            pid_idx = header.index("Protein ID")
            ga_idx = header.index("Gene Annotation")
        except ValueError:
            return {}

        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) <= max(pid_idx, ga_idx):
                continue
            protein_id = parts[pid_idx]
            if require_signalp and protein_id not in signalp_positive:
                continue

            tokens = gene_domain_tokens(parts[ga_idx])
            # Group this gene's own domain tokens by family
            family_tokens = {}
            for token in tokens:
                m = DIGESTIVE_RE.match(token)
                if m:
                    family_tokens.setdefault(m.group(0), []).append(token)

            gene_rows = dbcan_sub.get(protein_id, [])
            for family in family_tokens:
                merged = {}
                for subfamily_name, ec_field in gene_rows:
                    # match on family, not exact subfamily label: the annotation
                    # may carry an HMM-style label (GH13_14) while dbCAN-sub
                    # always reports eCAMI-style ones (GH13_e180)
                    if subfamily_name.split("_")[0] != family:
                        continue
                    for ec, cnt in parse_ec_field(ec_field):
                        merged[ec] = merged.get(ec, 0) + cnt
                suffix = resolve_family_ec(list(merged.items()))
                col = "%s_%s" % (family, suffix)
                counts[col] = counts.get(col, 0) + 1

    return counts


def main():
    genome_list_path = sys.argv[1] if len(sys.argv) > 1 else GENOME_LIST
    out_path = sys.argv[2] if len(sys.argv) > 2 else OUT_TSV
    mode = sys.argv[3] if len(sys.argv) > 3 else "secreted"
    if mode not in ("secreted", "all_digestive"):
        sys.exit("Unknown mode: %s (expected secreted or all_digestive)" % mode)
    require_signalp = mode == "secreted"
    reference_table = sys.argv[4] if len(sys.argv) > 4 else OUT_TSV

    genomes = load_genome_list(genome_list_path)
    all_counts = {}
    all_columns = set()

    for i, accession in enumerate(genomes, 1):
        counts = process_genome(accession, require_signalp=require_signalp)
        all_counts[accession] = counts
        all_columns.update(counts.keys())
        if i % 1000 == 0:
            print("Processed %d/%d genomes" % (i, len(genomes)), file=sys.stderr, flush=True)

    columns = sorted(all_columns)
    if not require_signalp:
        if not os.path.isfile(reference_table):
            sys.exit("all_digestive mode needs the secreted table header: %s not found" % reference_table)
        with open(reference_table) as f:
            columns = next(csv.reader(f, delimiter="\t"))[1:]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", newline="") as f:
        writer = csv.writer(f, delimiter="\t")
        # PICRUSt2's wrap_hsp.py indexes on a column literally named "assembly"
        writer.writerow(["assembly"] + columns)
        for accession in genomes:
            counts = all_counts.get(accession, {})
            writer.writerow([accession] + [counts.get(c, 0) for c in columns])

    print("Wrote %d genomes x %d trait columns to %s" % (len(genomes), len(columns), out_path))


if __name__ == "__main__":
    main()
