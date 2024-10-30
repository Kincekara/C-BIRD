version 1.0

import "wf_insert_size.wdl" as insert

workflow multiinsert {
    input {
    File inputSamplesFile
    Array[Array[File]] inputSamples = read_tsv(inputSamplesFile)
    }

    scatter (sample in inputSamples) {
        call insert.estimate_inserts {
            input:
            taxon = sample[0],
            samplename = sample[1],
            read1 = sample[2],
            read2 = sample[3]        
        }
    }
}