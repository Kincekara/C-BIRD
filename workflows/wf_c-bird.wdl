version 1.0

import "../tasks/task_version.wdl" as version
# import "../tasks/task_fastqc.wdl" as fastqc
import "../tasks/task_fastp.wdl" as fastp
import "../tasks/task_spades.wdl" as spades
import "../tasks/task_quast.wdl" as quast
import "../tasks/task_mlst.wdl" as mlst
import "../tasks/task_resfinder.wdl" as amr
import "../tasks/task_plasmidfinder.wdl" as plasmid
import "../tasks/task_busco.wdl" as busco
import "../tasks/task_taxonomy.wdl" as taxon
import "../tasks/task_report.wdl" as report

workflow cbird_workflow {
  
  meta {
  description: "CT-PHL Bacterial Identification and Resistance Detection pipeline"
  }

  input {
    File read1
    File read2
    File adapters
    String samplename
    File kraken2_db
    File db_resfinder
    File plasmidfinder_db
    File busco_db
    File genome_stats
  }
 
  call version.version_capture {
    input:
  }

  # call fastqc.fastqc_pe as fastqc_raw {
  #   input:
  #     read1 = read1,
  #     read2 = read2
  # }
  
  call fastp.fastp_pe as fastp_trim {
    input:
      read1 = read1,
      read2 = read2,
      samplename = samplename,
      adapters = adapters
  }

  # call fastqc.fastqc_pe as fastqc_trim {
  #   input:
  #     read1 = fastp_trim.read1_trimmed,
  #     read2 = fastp_trim.read2_trimmed
  # }

  call taxon.taxon {
    input:
    samplename = samplename,
    read1 = fastp_trim.read1_trimmed,
    read2 = fastp_trim.read2_trimmed,    
    kraken2_db = kraken2_db
  }

  call spades.spades_pe as assembly {
    input:
    samplename = samplename,
    read1 = fastp_trim.read1_trimmed,
    read2 = fastp_trim.read2_trimmed        
  }

  call quast.quast {
    input:
    samplename = samplename,
    assembly = assembly.scaffolds_trim  
  }

  call busco.busco {
    input:
    samplename = samplename,
    assembly = assembly.scaffolds_trim,
    busco_db = busco_db
  }

  call mlst.ts_mlst {
    input:
    samplename = samplename,
    assembly = assembly.scaffolds_trim
  }

  call amr.resfinder {
    input:
    samplename = samplename,
    assembly = assembly.scaffolds_trim,
    db_resfinder = db_resfinder
  }

  call plasmid.plasmidfinder {
    input:
    samplename = samplename,
    assembly = assembly.scaffolds_trim,
    plasmidfinder_db = plasmidfinder_db 
  }

  call report.generate_report {
    input:
    samplename = samplename,
    genome_stats = genome_stats,
    q30_bases = fastp_trim.q30_bases,
    taxon_report = taxon.bracken_report,
    mlst_report = ts_mlst.ts_mlst_results,
    amr_report = resfinder.resfinder_report,
    plasmid_report = plasmidfinder.plasmid_report
  }

  output {
    # Version 
    String cbird_version = version_capture.cbird_version
    String cbird_analysis_date = version_capture.date    
    # FastP
    String fastp_version = fastp_trim.fastp_version
    String fastp_docker = fastp_trim.fastp_docker
    File read1_trimmed = fastp_trim.read1_trimmed
    File read2_trimmed = fastp_trim.read2_trimmed
    File fastp_report = fastp_trim.fastp_report    
    Float q30_raw = fastp_trim.q30_raw
    Float q30_trimmed = fastp_trim.q30_trim
    # Kraken2
    String kraken2_version = taxon.kraken2_version
    String kraken2_docker = taxon.kraken2_docker
    File kraken2_report = taxon.kraken2_report
    # Bracken
    # String bracken_version = taxon.bracken_version
    String bracken_docker = taxon.bracken_docker
    File bracken_report = taxon.bracken_report
    String bracken_taxon = taxon.bracken_taxon
    # Spades
    String spades_version = assembly.spades_version
    String spades_docker = assembly.spades_docker
    File scaffolds = assembly.scaffolds
    File contigs = assembly.contigs
    File scaffolds_trimmed = assembly.scaffolds_trim
    # Quast 
    String quast_version = quast.version
    String quast_docker = quast.quast_docker
    File quast_report = quast.quast_report    
    Int genome_length = quast.genome_length
    Int number_contigs = quast.number_contigs
    Int n50_value = quast.n50_value
    Float gc_content = quast.gc_content
    # BUSCO
    String busco_version = busco.busco_version
    String busco_docker = busco.busco_docker
    File busco_results = busco.busco_report 
    String busco_summary = busco.busco_summary
    String busco_lineage = busco.busco_db_name
    String busco_db_date = busco.busco_db_date
    # MLST
    String mlst_version = ts_mlst.ts_mlst_version
    String mlst_docker = ts_mlst.ts_mlst_docker
    String mlst = ts_mlst.ts_mlst_predicted_st
    String pubmlst_scheme = ts_mlst.ts_mlst_pubmlst_scheme
    File mlst_results = ts_mlst.ts_mlst_results
    # ResFinder
    String resfinder_version = resfinder.resfinder_version
    String resfinder_docker = resfinder.resfinder_docker
    File amr = resfinder.resfinder_report
    # PlasmidFinder
    String plasmidfinder_version = plasmidfinder.plasmidfinder_version
    String plasmidfinder_docker = plasmidfinder.plasmidfinder_docker
    File plasmids = plasmidfinder.plasmid_report
    # Report
    File final_report = generate_report.final_report
    String estimated_coverage = generate_report.sequencing_coverage
    # # FastQC
    # File fastqc1_html = fastqc_raw.fastqc1_html
    # File fastqc1_zip = fastqc_raw.fastqc1_zip
    # File fastqc2_html = fastqc_raw.fastqc2_html
    # File fastqc2_zip = fastqc_raw.fastqc2_zip
    # Int read1_seq = fastqc_raw.read1_seq
    # Int read2_seq = fastqc_raw.read2_seq
    # String read_pairs = fastqc_raw.read_pairs
    # File fastqc1_trimmed_html = fastqc_trim.fastqc1_html
    # File fastqc1_trimmed_zip = fastqc_trim.fastqc1_zip
    # File fastqc2_trimmed_html = fastqc_trim.fastqc2_html
    # File fastqc2_trimmed_zip = fastqc_trim.fastqc2_zip    
    # Int read1_trimmed_seq = fastqc_trim.read1_seq
    # Int read2_trimmed_seq = fastqc_trim.read2_seq
    }
}