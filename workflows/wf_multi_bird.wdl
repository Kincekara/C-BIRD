version 1.0

import "wf_c-bird.wdl" as cbird

workflow multibird {
    input {
    File inputSamplesFile
    Array[Array[File]] inputSamples = read_tsv(inputSamplesFile)
    File? adapters
    File kraken2_database
    File checkm2_database
    File mash_reference   
    File? target_genes_fasta
    Int minimum_total_reads = 30000
    }

    scatter (sample in inputSamples) {
        call cbird.cbird_workflow {
            input:
            samplename = sample[0],
            read1 = sample[1],
            read2 = sample[2],            
            adapters = adapters,
            kraken2_database = kraken2_database,
            checkm2_db = checkm2_database,
            mash_reference = mash_reference,
            minimum_total_reads = minimum_total_reads,
            target_genes_fasta = target_genes_fasta,
        }
    }
}