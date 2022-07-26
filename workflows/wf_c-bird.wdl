version 1.0
import "../tasks/task_version.wdl" as version
import "../tasks/task_fastqc.wdl" as fastqc
import "../tasks/task_trimmomatic.wdl" as trimmomatic
import "../tasks/task_fastp.wdl" as fastp
import "../tasks/task_kraken2.wdl" as kraken
import "../tasks/task_spades.wdl" as spades
import "../tasks/task_quast.wdl" as quast
import "../tasks/task_bracken.wdl" as bracken
import "../tasks/task_mlst.wdl" as mlst
import "../tasks/task_resfinder.wdl" as amr
import "../tasks/task_plasmidfinder.wdl" as plasmid
import "../tasks/task_busco.wdl" as busco
   
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
  }
 
  call version.version_capture {
    input:
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
    kraken2_db = kraken2_db,
    kraken2_args ="--confidence 0.05"
  }

  call bracken.bracken as bracken_taxon{
    input:
    samplename = samplename,
    kraken_report = taxon.kraken2_report,
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

# call kraken.rekraken as rekraken {
#     input:
#     samplename = samplename,
#     seqs = assembly.scaffolds_trim,
#     kraken2_db = kraken2_db
#   }

# call bracken.bracken as bracken_rekraken{
#     input:
#     samplename = samplename,
#     kraken_report = rekraken.kraken2_report,
#     kraken2_db = kraken2_db,
#     threshold = 1
#   }

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
  output {
    # Version 
    String cbird_version = version_capture.cbird_version
    String cbird_analysis_date = version_capture.date
    # FastQC
    File fastqc1_html = fastqc_raw.fastqc1_html
    File fastqc1_zip = fastqc_raw.fastqc1_zip
    File fastqc2_html = fastqc_raw.fastqc2_html
    File fastqc2_zip = fastqc_raw.fastqc2_zip
    Int read1_seq = fastqc_raw.read1_seq
    Int read2_seq = fastqc_raw.read2_seq
    String read_pairs = fastqc_raw.read_pairs
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
    # FastP
    File read1_trimmed = fastp_trim.read1_trimmed
    File read2_trimmed = fastp_trim.read2_trimmed
    File fastp_report = fastp_trim.fastp_report
    String fastp_version = fastp_trim.fastp_version
    Float q30_raw = fastp_trim.q30_raw
    Float q30_trimmed = fastp_trim.q30_trim
    # Kraken2
    String kraken2_version = taxon.kraken2_version
    String kraken2_docker = taxon.kraken2_docker
    File kraken2_report = taxon.kraken2_report
    # File kraken2_classified_report = taxon.kraken2_classified_report
    # File kraken2_unclassified_read1 = taxon.kraken2_unclassified_read1
    # File kraken2_unclassified_read2 = taxon.kraken2_unclassified_read2
    # File kraken2_classified_read1 = taxon.kraken2_classified_read1
    # File kraken2_classified_read2 = taxon.kraken2_classified_read2
    String spades_version = assembly.spades_version
    File scaffolds = assembly.scaffolds
    File contigs = assembly.contigs
    File scaffolds_trim = assembly.scaffolds_trim
    File? quast_report = quast.quast_report
    String? quast_version = quast.version
    Int? genome_length = quast.genome_length
    Int? number_contigs = quast.number_contigs
    Int? n50_value = quast.n50_value
    # String rekraken_version = rekraken.kraken2_version
    # String rekraken_docker = rekraken.kraken2_docker
    # File rekraken_report = rekraken.kraken2_report
    File bracken_txn_report = bracken_taxon.bracken_report
    File bracken_txn = bracken_taxon.top_taxon
    # File braken_rekraken_report = bracken_rekraken.bracken_report
    File mlst = ts_mlst.ts_mlst_results
    File amr = resfinder.resfinder_report
    File plasmid = plasmidfinder.plasmid_report
    File busco_results = busco.busco_report
    String busco_version = busco.busco_version
    }
}