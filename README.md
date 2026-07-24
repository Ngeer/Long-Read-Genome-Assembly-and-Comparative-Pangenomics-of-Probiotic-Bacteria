# ProbioLR-NF
### A reproducible long-read genomics pipeline for probiotic strain characterization

**Industry context:** Probiotic manufacturers, nutraceutical companies, and functional food producers increasingly need to genomically verify what's actually inside their products — confirming strain identity and understanding what functional traits (metabolic pathways, stress tolerance, adhesion factors) a given strain actually carries before making health claims. This pipeline demonstrates that core workflow — from raw reads to a validated, annotated, comparative genome assembly — on real long-read sequencing data from three probiotic-relevant bacterial species.

> **Note on scope:** this pipeline covers assembly, annotation, and comparative pangenome analysis. It does **not** currently include dedicated antimicrobial resistance (AMR) or virulence factor screening — tools like AMRFinderPlus or ABRicate would be needed for that, and are a natural next extension (see *Next Steps* below), since AMR gene screening is in fact a standard regulatory expectation for any strain intended for human/animal consumption.

---

## What this project does

Starting from raw long-read sequencing data (Oxford Nanopore and PacBio) for three probiotic bacteria — *Lactiplantibacillus plantarum*, *Levilactobacillus brevis*, and *Bifidobacterium animalis* — this pipeline:

1. **Assesses raw data quality** before any processing (NanoPlot)
2. **Cleans the data** — removes duplicate reads, trims to an appropriate sequencing depth per platform (SeqKit, Filtlong)
3. **Assembles complete bacterial genomes** from the reads (Flye)
4. **Polishes** the assemblies to correct long-read error rates (Medaka)
5. **Annotates genes and predicts function** (Bakta)
6. **Validates assembly completeness** against a universal bacterial gene set (BUSCO)
7. **Compares all three genomes** to identify shared vs. strain-specific genes (Panaroo)
8. **Visualizes the comparative results** (R / ggplot2 / ggvenn)

The entire pipeline is built in **Nextflow (DSL2)**, fully containerized with **Docker**, and runs reproducibly on any machine with Docker installed — no manual tool installation required.

---

## Why this matters industrially

- **Strain verification & QC:** Confirms a probiotic product genuinely contains the species/strain it claims to, using whole-genome evidence rather than a single marker gene.
- **Functional trait discovery:** Identifies which genes each strain actually carries — relevant for substantiating specific health claims (e.g. bile tolerance, adhesion, specific metabolite production).
- **Comparative genomics for formulation decisions:** The pangenome analysis below shows exactly how genetically distinct these three species are — directly relevant when deciding which strain combinations offer genuinely complementary functional traits in a multi-strain probiotic blend, versus redundant ones.
- **Reproducibility for regulatory/QA documentation:** Nextflow + Docker means this exact analysis can be re-run identically by any downstream user (auditor, collaborator, regulator) — a meaningful advantage over ad hoc analysis scripts.

---

## Key results

### Genome assembly completeness (BUSCO)

| Sample | Species | Platform | Completeness |
|---|---|---|---|
| B_animalis | *Bifidobacterium animalis* | Nanopore | **100.0%** (124/124 core genes) |
| L_brevis | *Levilactobacillus brevis* | PacBio RS II | 87.9% (after coverage optimization) |
| L_plantarum | *Lactiplantibacillus plantarum* | PacBio RS II | 89.5% (after coverage optimization) |

All three assemblies were validated against the universal bacterial single-copy ortholog set (`bacteria_odb10`, n=124 genes) to confirm they represent genuinely complete, trustworthy genomes rather than just "the pipeline ran without crashing."

### Comparative pangenome analysis

![Pangenome Venn Diagram](results/pangenome_venn.png)

Out of **6,132 total genes** identified across all three species:

| Category | Gene count | % of total |
|---|---|---|
| **Core genes** (shared by all 3) | 41 | 0.7% |
| **Shell genes** (shared by 1–2 species) | 6,091 | 99.3% |

![Pangenome Category Breakdown](results/pangenome_categories.png)

**What this tells us:** these three species are genuinely distinct at the genomic level — despite all being classified as "probiotic bacteria," they share almost no genes in common (41 out of 6,132). Nearly everything that defines each species' function is unique to that species. This is a directly useful finding for product formulation: combining genomically distant strains like these in a multi-strain product means combining genuinely non-redundant functional capabilities, rather than three strains that are mostly duplicating each other's genes.

---

## Tech stack

| Stage | Tool |
|---|---|
| Workflow orchestration | Nextflow (DSL2) |
| Containerization | Docker |
| QC | NanoPlot |
| Deduplication | SeqKit |
| Read filtering | Filtlong |
| Assembly | Flye |
| Polishing | Medaka |
| Annotation | Bakta |
| Completeness validation | BUSCO |
| Pangenome analysis | Panaroo |
| Visualization | R (tidyverse, ggplot2, ggvenn) |

---

## Repository structure

```
ProbioLR-NF/
├── main.nf                      # Pipeline definition
├── nextflow.config               # Resource allocation & execution settings
├── raw_reads/                    # Input FASTQ files (not included — see Data below)
├── results/
│   ├── qc/                       # NanoPlot reports
│   ├── filtered/                 # Filtlong-trimmed reads
│   ├── assembly/                 # Flye genome assemblies
│   ├── polished/                 # Medaka-polished consensus genomes
│   ├── annotation/               # Bakta gene annotations
│   ├── pangenome/                # Panaroo comparative genomics output
│   ├── pangenome_venn.png
│   ├── pangenome_categories.png
│   └── reports/                  # Nextflow execution reports (timeline, trace, DAG)
├── pangenome_visualization.R      # R script for pangenome figures
└── README.md
```

## Running the pipeline

```bash
nextflow run main.nf -profile docker
```

Requires Docker and Nextflow installed. All bioinformatics tools run in pre-built containers — no manual tool installation needed.

---

## Data

Raw sequencing data used in this project originates from public SRA accessions (long-read WGS data for the three species listed above). Due to file size, raw reads are not included in this repository; accession numbers available on request.

---

---

## Next steps (not yet implemented)

- **AMR gene screening** (AMRFinderPlus or ABRicate) — checking each genome for antibiotic resistance genes, particularly transferable resistance elements, which is a standard safety requirement for any strain marketed for human or animal consumption.
- **Virulence factor screening** (e.g. VFDB via ABRicate) — confirming the absence of known virulence-associated genes.
- **Plasmid characterization** — several contigs in these assemblies are plasmid-sized; confirming plasmid identity and checking whether they carry any mobile resistance elements would meaningfully strengthen the safety picture.

These were intentionally left out of this iteration to focus on getting a validated, reproducible assembly-to-pangenome pipeline working end to end first — but they're the logical next layer for anyone using this as a real strain-safety screening tool rather than a functional/comparative genomics demo.

---

## Author

**Stuart Ngereza** — Bioinformatician, Dar es Salaam, Tanzania
Background in molecular biology, bioinformatics pipeline development, and scientific visualization, with a focus on applied genomics for food tech, pharma, and nutraceutical applications.
