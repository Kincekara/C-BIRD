version 1.0

import "wf_c-bird.wdl" as cbird

workflow multibird {
    input {
    File inputSamplesFile
    Array[Array[File]] inputSamples = read_tsv(inputSamplesFile)
    File adapters
    File kraken2_database
    File mash_reference   
    File plasmidfinder_database
    File busco_database
    File genome_stats_file
    File amrfinder_database
    Int minimum_total_reads = 7472
    Boolean html_report = true
    }

    scatter (sample in inputSamples) {
        call cbird.cbird_workflow {
            input:
            samplename = sample[0],
            read1 = sample[1],
            read2 = sample[2],            
            adapters = adapters,
            kraken2_database = kraken2_database,
            mash_reference = mash_reference,
            plasmidfinder_database = plasmidfinder_database,
            busco_database = busco_database,
            genome_stats_file = genome_stats_file,
            amrfinder_database = amrfinder_database,
            minimum_total_reads = minimum_total_reads,
            html_report = html_report
        }
    }
}