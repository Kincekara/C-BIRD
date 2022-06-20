version 1.0

import  "../tasks/task_fastqc.wdl" as fastqc
import "../task/task_trimmomatics.wdl" as trimmomatic
   
workflow cbiard_workflow {
  
  meta {
  description: "Runs basic QC (FastQC)"
  }

  input {
    File read1
    File read2
  }

  call fastqc.fastqc_pe as fastqc_raw {
    input:
      read1 = read1,
      read2 = read2
  }
  
  call trimmomatic.trimmomatic_pe as trim
    input:
    read1 = read1,
    read2 = read2

  output {
    File fastqc1_html = fastqc_raw.fastqc1_html
    File fastqc1_zip = fastqc_raw.fastqc1_zip
    File fastqc2_html = fastqc_raw.fastqc2_html
    File fastqc2_zip = fastqc_raw.fastqc2_zip
    Int read1_seq = fastqc_raw.read1_seq
    Int read2_seq = fastqc_raw.read2_seq
    # String read_pairs = fastqc_raw.read_pairs
    # String version = read_string("VERSION")
    # String pipeline_date = read_string("DATE")

    }
}