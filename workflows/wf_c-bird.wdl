version 1.0

import "../tasks/task_version.wdl" as version
import "../tasks/task_fastp.wdl" as fastp
import "../tasks/task_bbduk.wdl" as bbduk
import "../tasks/task_spades.wdl" as spades
import "../tasks/task_quast.wdl" as quast
import "../tasks/task_mlst.wdl" as mlst
import "../tasks/task_amrfinderplus.wdl" as amrplus
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
    String samplename
    File adapters
    File kraken2_database
    File plasmidfinder_database
    File busco_database
    File genome_stats_file
    File amrfinder_database
    Int minimum_total_reads = 7472
  }
 
  call version.version_capture {
    input:
  }

  call fastp.fastp_pe as fastp_trim {
    input:
      read1 = read1,
      read2 = read2,
      samplename = samplename,
      adapters = adapters      
  }

  if ( fastp_trim.total_reads > minimum_total_reads) {
    
    call bbduk.bbduk_pe {
      input:
      read1_trimmed = fastp_trim.read1_trimmed,
      read2_trimmed = fastp_trim.read2_trimmed,
      samplename =samplename
    }

    call taxon.taxon {
      input:
      samplename = samplename,
      read1 = bbduk_pe.read1_clean,
      read2 = bbduk_pe.read2_clean,    
      kraken2_db = kraken2_database
    }

    call spades.spades_pe as assembly {
      input:
      samplename = samplename,
      read1 = bbduk_pe.read1_clean,
      read2 = bbduk_pe.read2_clean        
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
      busco_db = busco_database
    }

    call mlst.ts_mlst {
      input:
      samplename = samplename,
      assembly = assembly.scaffolds_trim
    }

    call amrplus.amrfinderplus_nuc as amrfinder {
      input:
      samplename = samplename,
      assembly = assembly.scaffolds_trim,
      amr_db = amrfinder_database,
      organism = taxon.bracken_taxon
    }

    call plasmid.plasmidfinder {
      input:
      samplename = samplename,
      assembly = assembly.scaffolds_trim,
      plasmidfinder_db = plasmidfinder_database
    }

    call report.generate_report {
      input:
      samplename = samplename,
      genome_stats = genome_stats_file,
      q30_bases = fastp_trim.q30_bases,
      taxon_report = taxon.bracken_report_filter,
      mlst_report = ts_mlst.ts_mlst_results,
      amr_report = amrfinder.amrfinderplus_all_report,
      plasmid_report = plasmidfinder.plasmid_report,
      fastp_report = fastp_trim.fastp_report,
      taxid = taxon.taxid,
      version = version_capture.cbird_version,
      phix_ratio = bbduk_pe.phix_ratio,
      genome_length = quast.genome_length,
      quast_report = quast.quast_report,
      busco_report = busco.busco_json
    }
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
    Int total_reads = fastp_trim.total_reads    
    Int r1_reads =  fastp_trim.r1_reads
    Int r2_reads = fastp_trim.r2_reads
    Float? r1_q30_raw = fastp_trim.r1_q30_raw
    Float? r2_q30_raw = fastp_trim.r2_q30_raw
    Float? r1_q30_trim = fastp_trim.r1_q30_trim
    Float? r2_q30_trim = fastp_trim.r2_q30_trim
    # BBduk
    File? read1_clean = bbduk_pe.read1_clean
    File? read2_clean = bbduk_pe.read2_clean
    File? phiX_stats = bbduk_pe.phiX_stats
    String? bbduk_docker = bbduk_pe.bbduk_docker
    String? bbduk_version = bbduk_pe.bbduk_version
    String? phiX_ratio = bbduk_pe.phix_ratio
    # Kraken2
    String? kraken2_version = taxon.kraken2_version
    String? kraken2_db_version = taxon.kraken2_db_version
    String? kraken2_docker = taxon.kraken2_docker
    File? kraken2_report = taxon.kraken2_report
    # Bracken
    String? bracken_version = taxon.bracken_version
    String? bracken_docker = taxon.bracken_docker
    File? bracken_report = taxon.bracken_report
    String? bracken_taxon = taxon.bracken_taxon
    Float? bracken_taxon_ratio = taxon.top_taxon_ratio
    # Spades
    String? spades_version = assembly.spades_version
    String? spades_docker = assembly.spades_docker
    File? scaffolds = assembly.scaffolds
    File? contigs = assembly.contigs
    File? scaffolds_trimmed = assembly.scaffolds_trim
    # Quast 
    String? quast_version = quast.version
    String? quast_docker = quast.quast_docker
    File? quast_report = quast.quast_report    
    Int? genome_length = quast.genome_length
    Int? number_contigs = quast.number_contigs
    Int? n50_value = quast.n50_value
    Float? gc_content = quast.gc_content
    # BUSCO
    String? busco_version = busco.busco_version
    String? busco_docker = busco.busco_docker
    File? busco_results = busco.busco_report 
    String? busco_summary = busco.busco_summary
    String? busco_lineage = busco.busco_db_name
    String? busco_db_date = busco.busco_db_date
    # MLST
    String? mlst_version = ts_mlst.ts_mlst_version
    String? mlst_docker = ts_mlst.ts_mlst_docker
    String? mlst = ts_mlst.ts_mlst_predicted_st
    String? pubmlst_scheme = ts_mlst.ts_mlst_pubmlst_scheme
    File? mlst_results = ts_mlst.ts_mlst_results
    # AMRFinderPlus
    File? amr_report = amrfinder.amrfinderplus_all_report
    String? amr_genes = amrfinder.amrfinderplus_amr_genes
    String? amr_stress_genes = amrfinder.amrfinderplus_stress_genes
    String? amr_virulance_genes = amrfinder.amrfinderplus_virulence_genes
    String? amrfinderplus_version = amrfinder.amrfinderplus_version
    String? amrfinderplus_db_version = amrfinder.amrfinderplus_db_version
    # PlasmidFinder
    String? plasmidfinder_version = plasmidfinder.plasmidfinder_version
    String? plasmidfinder_db_date = plasmidfinder.plasmidfinder_db_date
    String? plasmidfinder_docker = plasmidfinder.plasmidfinder_docker
    String? plasmidfinder_plasmids = plasmidfinder.plasmids
    File? plasmidfinder_report = plasmidfinder.plasmid_report
    # Report
    File? summary_txt_report = generate_report.txt_report
    File? summary_html_report = generate_report.html_report
    File? summary_qc_report = generate_report.qc_report
    Float? est_sequencing_depth = generate_report.sequencing_depth
    Float? est_genome_ratio = generate_report.genome_ratio
    }
}