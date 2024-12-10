version 1.0

import "../tasks/task_version.wdl" as version
import "../tasks/task_fastp.wdl" as fastp
import "../tasks/task_bbtools.wdl" as bbtools
import "../tasks/task_spades.wdl" as spades
import "../tasks/task_quast.wdl" as quast
import "../tasks/task_mlst.wdl" as mlst
import "../tasks/task_amrfinderplus.wdl" as amrplus
import "../tasks/task_plasmidfinder.wdl" as plasmid
import "../tasks/task_busco.wdl" as busco
import "../tasks/task_checkm2.wdl" as checkm2
import "../tasks/task_taxonomy.wdl" as taxon
import "../tasks/task_mash.wdl" as mash
import "../tasks/task_blast.wdl" as blast
import "../tasks/task_report.wdl" as report
import "../tasks/task_qc_check.wdl" as qc_check
import "../tasks/task_json.wdl" as json

workflow cbird_workflow {
  
  meta {
  description: "CT-PHL Bacterial Identification and Resistance Detection pipeline"
  }

  input {
    File read1
    File read2
    String samplename
    File? adapters
    File kraken2_database
    File mash_reference 
    File checkm2_db  
    File? target_genes_fasta
    Int minimum_total_reads = 30000
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
    
    call bbtools.assembly_prep {
      input:
      read1_trimmed = fastp_trim.read1_trimmed,
      read2_trimmed = fastp_trim.read2_trimmed,
      total_reads = fastp_trim.total_reads,   
      samplename =samplename
    }

    call taxon.profile {
      input:
      samplename = samplename,
      read1 = assembly_prep.read1_clean_norm,
      read2 = assembly_prep.read2_clean_norm,    
      kraken2_db = kraken2_database
    }
    
    call spades.spades_pe as assembly {
      input:
      samplename = samplename,
      read1 = assembly_prep.read1_clean_norm,
      read2 = assembly_prep.read2_clean_norm,
      contig_threshold = fastp_trim.read_length * 2    
    }

    if (defined(target_genes_fasta)) {
      call blast.tblastn {
        input:
        samplename = samplename,
        query = target_genes_fasta,
        subject = assembly.scaffolds_trim
      }
    }

    if ( profile.bracken_genus == "Acinetobacter" || profile.bracken_genus == "Burkholderia" || profile.bracken_genus == "Citrobacter" || 
    profile.bracken_genus == "Enterobacter" || profile.bracken_genus == "Escherichia" || profile.bracken_genus == "Klebsiella" || 
    profile.bracken_genus == "Kluyvera" || profile.bracken_genus == "Metapseudomonas" || profile.bracken_genus == "Morganella" || 
    profile.bracken_genus == "Neisseria" || profile.bracken_genus == "Proteus" || profile.bracken_genus == "Providencia" || 
    profile.bracken_genus == "Pseudomonas" || profile.bracken_genus == "Raoultella" || profile.bracken_genus == "Salmonella" || 
    profile.bracken_genus == "Serratia" || profile.bracken_genus == "Streptococcus") {

      call mash.predict_taxon {
        input:
        samplename = samplename,
        assembly = assembly.scaffolds_trim,
        reference = mash_reference        
      }
    }

    call quast.quast {
      input:
      samplename = samplename,
      assembly = assembly.scaffolds_trim  
    }

    call busco.busco {
      input:
      samplename = samplename,
      assembly = assembly.scaffolds_trim
    }

    call checkm2.checkm2 {
      input:
      samplename = samplename,
      assembly = assembly.scaffolds_trim,
      checkm2_db = checkm2_db
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
      bracken_organism = profile.bracken_taxon,
      mash_organism = predict_taxon.taxon,
      prodigal_faa = checkm2.prodigal_faa,
      prodigal_gff = checkm2.prodigal_gff
    }

    call plasmid.plasmidfinder {
      input:
      samplename = samplename,
      assembly = assembly.scaffolds_trim
    }

    call report.generate_report {
      input:
      samplename = samplename,
      total_bases = fastp_trim.total_bases,
      taxon_report = profile.bracken_report_filter,
      mlst_report = ts_mlst.ts_mlst_results,
      amr_report = amrfinder.amrfinderplus_all_report,
      plasmid_report = plasmidfinder.plasmid_report,
      fastp_report = fastp_trim.fastp_report,
      taxid = profile.taxid,
      version = version_capture.cbird_version,
      phix_ratio = assembly_prep.phix_ratio,
      genome_length = quast.genome_length,
      quast_report = quast.quast_report,
      busco_report = busco.busco_json,
      mash_result = predict_taxon.top_taxon,
      blast_result = tblastn.blast_results
    }

    call qc_check.qc {
      input:
      r1_q30_trim = fastp_trim.r1_q30_trim,
      r2_q30_trim = fastp_trim.r2_q30_trim,
      total_reads_trim = fastp_trim.total_reads_trim,
      coverage = generate_report.sequencing_depth,
      coverage_trim = generate_report.sequencing_depth_trim,
      number_of_scaffolds = quast.number_contigs,
      busco_summary = busco.busco_summary,
      genome_ratio = generate_report.genome_ratio
    }

    call json.write_json {
      input:
      samplename = samplename,
      cbird_version = version_capture.cbird_version,
      cbird_analysis_date = version_capture.date,
      total_reads = fastp_trim.total_reads,
      total_reads_trim = fastp_trim.total_reads_trim,
      r1_reads =  fastp_trim.r1_reads,
      r2_reads = fastp_trim.r2_reads,
      r1_q30_raw = fastp_trim.r1_q30_raw,
      r2_q30_raw = fastp_trim.r2_q30_raw,
      r1_q30_trim = fastp_trim.r1_q30_trim,
      r2_q30_trim = fastp_trim.r2_q30_trim,
      phiX_ratio = assembly_prep.phix_ratio,
      bracken_taxon = profile.bracken_taxon,
      bracken_taxon_ratio = profile.top_taxon_ratio,
      predicted_organism = predict_taxon.taxon,
      percent_identity = predict_taxon.ratio,
      genome_length = quast.genome_length,
      number_of_contigs = quast.number_contigs,
      n50_value = quast.n50_value,
      gc_content = quast.gc_content,
      contamination = checkm2.contamination,
      completeness =  checkm2.completeness,
      mlst = ts_mlst.ts_mlst_predicted_st,
      pubmlst_scheme = ts_mlst.ts_mlst_pubmlst_scheme,
      amr_genes = amrfinder.amrfinderplus_amr_genes,
      amr_stress_genes = amrfinder.amrfinderplus_stress_genes,
      amr_virulance_genes = amrfinder.amrfinderplus_virulence_genes,
      amr_subclass = amrfinder.amrfinderplus_amr_subclass,
      plasmidfinder_plasmids = plasmidfinder.plasmids,
      blast_genes = tblastn.genes,
      est_sequencing_depth = generate_report.sequencing_depth,
      est_sequencing_depth_trim = generate_report.sequencing_depth_trim,
      est_genome_ratio = generate_report.genome_ratio,
      qc_eval = qc.qc_eval
    }    
  }

  output {
    # Version 
    String cbird_version = version_capture.cbird_version
    String cbird_analysis_date = version_capture.date    
    # FastP
    String fastp_version = fastp_trim.fastp_version
    String fastp_docker = fastp_trim.fastp_docker
    File fastp_report = fastp_trim.fastp_report
    Int total_reads = fastp_trim.total_reads
    Int total_reads_trim = fastp_trim.total_reads_trim
    Int r1_reads =  fastp_trim.r1_reads
    Int r2_reads = fastp_trim.r2_reads
    Float? r1_q30_raw = fastp_trim.r1_q30_raw
    Float? r2_q30_raw = fastp_trim.r2_q30_raw
    Float? r1_q30_trim = fastp_trim.r1_q30_trim
    Float? r2_q30_trim = fastp_trim.r2_q30_trim
    # BBtools
    File? phiX_stats = assembly_prep.phiX_stats
    String? bbtools_docker = assembly_prep.bbtools_docker
    String? bbtools_version = assembly_prep.bbmap_version
    String? phiX_ratio = assembly_prep.phix_ratio
    # CheckM2 
    File? checkm2_report = checkm2.report
    String? checkm2_docker = checkm2.checkm2_docker
    String? completeness = checkm2.completeness
    String? contamination = checkm2.contamination
    # Kraken2
    String? kraken2_version = profile.kraken2_version
    String? kraken2_db_version = profile.kraken2_db_version
    String? kraken2_docker = profile.kraken2_docker
    File? kraken2_report = profile.kraken2_report
    # Bracken
    String? bracken_version = profile.bracken_version
    String? bracken_docker = profile.bracken_docker
    File? bracken_report = profile.bracken_report_filter
    String? bracken_taxon = profile.bracken_taxon
    Float? bracken_taxon_ratio = profile.top_taxon_ratio
    # Spades
    String? spades_version = assembly.spades_version
    String? spades_docker = assembly.spades_docker
    File? scaffolds = assembly.scaffolds
    File? contigs = assembly.contigs
    File? scaffolds_trimmed = assembly.scaffolds_trim
    # Mash
    String? mash_version = predict_taxon.version
    File? mash_results = predict_taxon.screen
    String? predicted_organism = predict_taxon.taxon
    Float? percent_identity = predict_taxon.ratio
    String? mash_docker = predict_taxon.mash_docker
    # Quast 
    String? quast_version = quast.version
    String? quast_docker = quast.quast_docker
    File? quast_report = quast.quast_report    
    Int? genome_length = quast.genome_length
    Int? number_of_contigs = quast.number_contigs
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
    String? amr_subclass = amrfinder.amrfinderplus_amr_subclass
    String? amrfinderplus_docker = amrfinder.amrfinderplus_docker
    # PlasmidFinder
    String? plasmidfinder_version = plasmidfinder.plasmidfinder_version
    String? plasmidfinder_db_date = plasmidfinder.plasmidfinder_db_date
    String? plasmidfinder_docker = plasmidfinder.plasmidfinder_docker
    String? plasmidfinder_plasmids = plasmidfinder.plasmids
    File? plasmidfinder_report = plasmidfinder.plasmid_report
    # Blast
    File? blast_results = tblastn.blast_results
    String? blast_genes = tblastn.genes
    String? blast_docker = tblastn.blast_docker
    String? blast_version = tblastn.blast_version
    # Report
    File? clia_report = generate_report.clia_report
    File? summary_html_report = generate_report.html_report
    File? summary_qc_report = generate_report.qc_report
    Float? est_sequencing_depth = generate_report.sequencing_depth
    Float? est_sequencing_depth_trim = generate_report.sequencing_depth_trim
    Float? est_genome_ratio = generate_report.genome_ratio
    String? cbird_util_docker = generate_report.cbird_util_docker
    # QC Eval
    String? qc_eval = qc.qc_eval
    # Json
    File? json_report = write_json.json_report
    }
}