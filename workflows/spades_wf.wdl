version 1.0

import "../tasks/task_fastp.wdl" as fastp
import "../tasks/task_spades.wdl" as spades

workflow spades_test {
  
  meta {
  description: "test wf"
  }

  input {
    File read1
    File read2
    File adapters
    String samplename
  }

  call fastp.fastp_pe as fastp_trim {
    input:
      read1 = read1,
      read2 = read2,
      samplename = samplename,
      adapters = adapters
  }

  call spades.spades_pe as assembly {
    input:
    samplename = samplename,
    read1 = fastp_trim.read1_trimmed,
    read2 = fastp_trim.read2_trimmed        
  }

  output {
   # FastP
    String fastp_version = fastp_trim.fastp_version
    String fastp_docker = fastp_trim.fastp_docker
    File read1_trimmed = fastp_trim.read1_trimmed
    File read2_trimmed = fastp_trim.read2_trimmed
    File fastp_report = fastp_trim.fastp_report    
    Float q30_raw = fastp_trim.q30_raw
    Float q30_trimmed = fastp_trim.q30_trim
    # Spades
    String spades_version = assembly.spades_version
    String spades_docker = assembly.spades_docker
    File scaffolds = assembly.scaffolds
    File contigs = assembly.contigs
    File scaffolds_trimmed = assembly.scaffolds_trim
  }
}