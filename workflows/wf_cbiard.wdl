version 1.0

import "../tasks/task_fastqc.wdl" as fastqc
import "../tasks/task_trimmomatic.wdl" as trimmomatic
import "../tasks/task_fastp.wdl" as fastp
import "../tasks/task_kraken2.wdl" as kraken
   
workflow cbiard_workflow {
  
  meta {
  description: "Runs basic QC (FastQC)"
  }

  input {
    File read1
    File read2
    File adapters
    String samplename
    File kraken2_db
  }

  call fastqc.fastqc_pe as fastqc_raw {
    input:
      read1 = read1,
      read2 = read2
  }
  
  # call trimmomatic.trimmomatic_pe as trim {
  #   input:
  #   read1 = read1,
  #   read2 = read2,
  #   samplename = samplename,
  #   adapters = adapters
  # }

  call fastp.fastp_pe as fastp_trim {
    input:
      read1 = read1,
      read2 = read2,
      samplename = samplename,
      adapters = adapters
  }

  call fastqc.fastqc_pe as fastqc_trim {
    input:
      read1 = fastp_trim.read1_trimmed,
      read2 = fastp_trim.read2_trimmed
  }

  call kraken.kraken2_pe as taxon {
    input:
    samplename = samplename,
    read1 = fastp_trim.read1_trimmed,
    read2 = fastp_trim.read2_trimmed,    
    kraken2_db = kraken2_db
  }

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
    # File read1_trimmed = trim.read1_trimmed
    # File read2_trimmed = trim.read2_trimmed
    File fastqc1_trimmed_html = fastqc_trim.fastqc1_html
    File fastqc1_trimmed_zip = fastqc_trim.fastqc1_zip
    File fastqc2_trimmed_html = fastqc_trim.fastqc2_html
    File fastqc2_trimmed_zip = fastqc_trim.fastqc2_zip
    Int read1_trimmed_seq = fastqc_trim.read1_seq
    Int read2_trimmed_seq = fastqc_trim.read2_seq
    File read1_ftrimmed = fastp_trim.read1_trimmed
    File read2_ftrimmed = fastp_trim.read2_trimmed
    File fastp_report = fastp_trim.fastp_report
    File fastp_json = fastp_trim.fastp_json
    # Kraken2
    String kraken2_version = taxon.kraken2_version
    String kraken2_docker = taxon.kraken2_docker
    File kraken2_report = taxon.kraken2_report
    File kraken2_classified_report = taxon.kraken2_classified_report
    # File kraken2_unclassified_read1 = taxon.kraken2_unclassified_read1
    # File kraken2_unclassified_read2 = taxon.kraken2_unclassified_read2
    # File kraken2_classified_read1 = taxon.kraken2_classified_read1
    # File kraken2_classified_read2 = taxon.kraken2_classified_read2
    }
}