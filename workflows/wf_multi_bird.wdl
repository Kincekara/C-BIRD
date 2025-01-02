version 1.0

import "wf_c-bird.wdl" as cbird

workflow multibird {
    input {
    File inputSamplesFile
    Array[Array[String]] inputSamples = read_tsv(inputSamplesFile)
    File? adapters
    File kraken2_database
    File checkm2_database
    File? mash_reference   
    File? target_genes_fasta
    Int minimum_total_reads = 30000
    String? labid
    File? report_logo1
    File? report_logo2
    File? report_disclaimer
    String? header_line1
    String? header_line2
    String? header_line3
    String? header_line4
    String? header_line5
    String? header_line6
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
            labid = labid,
            report_logo1 = report_logo1,
            report_logo2 = report_logo2,
            report_disclaimer = report_disclaimer,
            header_line1 = header_line1,
            header_line2 = header_line2,
            header_line3 = header_line3,
            header_line4 = header_line4,
            header_line5 = header_line5,
            header_line6 = header_line6
        }
    }
}