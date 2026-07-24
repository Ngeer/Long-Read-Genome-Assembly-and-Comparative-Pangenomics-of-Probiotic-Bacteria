nextflow.enable.dsl=2

params.reads    = "raw_reads/*.fastq.gz"
params.outdir   = "results"
params.baktaDb  = System.getenv('HOME') + '/probiotics/bakta_db/db-light'

process QC_LONGREAD {
    tag { "$sample_id" }
    publishDir { "${params.outdir}/qc/${sample_id}" }, mode: 'copy'
    container 'staphb/nanoplot:latest'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*")

    script:
    """
    NanoPlot --fastq ${reads} -o . --plots dot
    """
}

process DEDUP_READS {
    tag { "$sample_id" }
    container 'staphb/seqkit:latest'

    input:
    tuple val(sample_id), val(platform), path(reads)

    output:
    tuple val(sample_id), val(platform), path("${sample_id}_dedup.fastq.gz"), emit: deduped

    script:
    """
    set -euo pipefail
    seqkit rmdup ${reads} -o ${sample_id}_dedup.fastq.gz
    """
}

process FILTER_READS {
    tag { "$sample_id" }
    publishDir { "${params.outdir}/filtered/${sample_id}" }, mode: 'copy'
    container 'staphb/filtlong:latest'

    input:
    tuple val(sample_id), val(platform), path(reads)

    output:
    tuple val(sample_id), val(platform), path("${sample_id}_filtered.fastq.gz"), emit: filtered

    script:
    def target_bases = (platform == "pacbio-raw") ? 360000000 : 200000000
    """
    set -euo pipefail
    filtlong --target_bases ${target_bases} ${reads} | gzip > ${sample_id}_filtered.fastq.gz
    """
}

process ASSEMBLY {
    tag { "$sample_id" }
    publishDir { "${params.outdir}/assembly/${sample_id}" }, mode: 'copy'
    container 'staphb/flye:latest'

    input:
    tuple val(sample_id), val(platform), path(reads)

    output:
    tuple val(sample_id), path("assembly.fasta"), emit: assembly

    script:
    """
    flye --${platform} ${reads} --out-dir . --threads ${task.cpus} --genome-size 2m
    """
}

process POLISH {
    tag { "$sample_id" }
    publishDir { "${params.outdir}/polished/${sample_id}" }, mode: 'copy'
    container 'staphb/medaka:latest'

    input:
    tuple val(sample_id), path(reads), path(assembly)

    output:
    tuple val(sample_id), path("consensus.fasta"), emit: polished

    script:
    """
    medaka_consensus -i ${reads} -d ${assembly} -o . -t ${task.cpus}
    """
}

process ANNOTATE {
    tag { "$sample_id" }
    publishDir { "${params.outdir}/annotation/${sample_id}" }, mode: 'copy'
    container 'staphb/bakta:latest'
    containerOptions "-v ${params.baktaDb}:/db"

    input:
    tuple val(sample_id), path(genome)

    output:
    tuple val(sample_id), path("*.gff3"), emit: annotation
    tuple val(sample_id), path("*.faa"), emit: proteins

    script:
    """
    bakta --db /db --force --output . --prefix ${sample_id} ${genome}
    """
}

process COMPARE_GENOMES {
    publishDir "${params.outdir}/pangenome", mode: 'copy'
    container 'staphb/panaroo:latest'

    input:
    path(gff_files)

    output:
    path("*")

    script:
    """
    panaroo -i ${gff_files} -o . --clean-mode strict -t ${task.cpus}
    """
}

workflow {

    def platformMap = [
        "L_plantarum" : "pacbio-raw",
        "L_brevis"    : "pacbio-raw",
        "B_animalis"  : "nano-raw"
    ]

    reads_ch = Channel
        .fromPath(params.reads)
        .map { file ->
            def id       = file.name.replaceAll(/\.fastq\.gz$/, '')
            def platform = platformMap[id] ?: "nano-raw"
            tuple(id, platform, file)
        }

    reads_ch.view { "Loaded sample: $it" }

    reads_only_ch = reads_ch.map { id, platform, file -> tuple(id, file) }

    QC_LONGREAD(reads_only_ch)

    dedup_ch = DEDUP_READS(reads_ch)

    filtered_ch = FILTER_READS(dedup_ch.deduped)

    assembly_ch = ASSEMBLY(filtered_ch.filtered)

    polished_ch = POLISH(reads_only_ch.join(assembly_ch))

    annot_ch = ANNOTATE(polished_ch)

    COMPARE_GENOMES(annot_ch.annotation.map { it[1] }.collect())
}
