version 1.0

task write_json {
  input {
    String samplename
    # Version 
    String cbird_version
    String cbird_analysis_date 
    # FastP
    Int total_reads
    Int total_reads_trim 
    Int r1_reads 
    Int r2_reads 
    Float? r1_q30_raw 
    Float? r2_q30_raw 
    Float? r1_q30_trim 
    Float? r2_q30_trim 
    # BBtools
    String? phiX_ratio 
    # Bracken
    String? bracken_taxon 
    Float? bracken_taxon_ratio 
    # Mash
    String? predicted_organism 
    Float? percent_identity 
    # Quast 
    Int? genome_length 
    Int? number_of_contigs 
    Int? n50_value 
    Float? gc_content 
    # BUSCO
    String? busco_summary 
    # MLST
    String? mlst 
    String? pubmlst_scheme 
    # AMRFinderPlus
    String? amr_genes 
    String? amr_stress_genes 
    String? amr_virulance_genes
    String? amr_subclass 
    # PlasmidFinder
    String? plasmidfinder_plasmids 
    # Blast
    String? blast_genes 
    # Report
    Float? est_sequencing_depth 
    Float? est_sequencing_depth_trim 
    Float? est_genome_ratio 
    # QC Eval
    String? qc_eval
  }
  command <<<
    cat <<EOF>> ~{samplename}_report.json
    {
      "version": "~{cbird_version}",
      "analysis_date": "~{cbird_analysis_date}",
      "summary":{
        "samplename": "~{samplename}",
        "predicted_organism": "~{predicted_organism} ~{percent_identity}",
        "amr_genes": "~{amr_genes}",
        "amr_resistance": "~{amr_subclass}"
      },
      "outputs": {
        "fastp": {
          "total_reads": "~{total_reads}",
          "total_reads_trim": "~{total_reads_trim}",
          "r1_reads": "~{r1_reads}",
          "r2_reads": "~{r2_reads}",
          "r1_q30_raw": "~{r1_q30_raw}",
          "r2_q30_raw": "~{r2_q30_raw}",
          "r1_q30_trim": "~{r1_q30_trim}",
          "r2_q30_trim": "~{r2_q30_trim}"
        },
        "bbtools": {
          "phiX_ratio": "~{phiX_ratio}"
        },
        "bracken": {
          "bracken_taxon": "~{bracken_taxon}",
          "bracken_taxon_ratio": "~{bracken_taxon_ratio}"
        },
        "mash": {
          "predicted_organism": "~{predicted_organism}",
          "percent_identity": "~{percent_identity}"
        },
        "quast": {
          "genome_length": "~{genome_length}",
          "number_of_contigs": "~{number_of_contigs}",
          "n50_value": "~{n50_value}",
          "gc_content": "~{gc_content}"
        },
        "busco": {
          "busco_summary": "~{busco_summary}"
        },
        "mlst": {
          "mlst": "~{mlst}",
          "pubmlst_scheme": "~{pubmlst_scheme}"
        },
        "amrfinderplus": {
          "amr_genes": "~{amr_genes}",
          "stress_genes": "~{amr_stress_genes}",
          "virulance_genes": "~{amr_virulance_genes}",
          "amr_subclass": "~{amr_subclass}"
        },
        "plasmidfinder": {
          "plasmids": "~{plasmidfinder_plasmids}"
        },
        "blast": {
          "genes": "~{blast_genes}"
        },
        "extras": {
          "est_sequencing_depth": "~{est_sequencing_depth}",
          "est_sequencing_depth_trim": "~{est_sequencing_depth_trim}",
          "est_genome_ratio": "~{est_genome_ratio}",
          "qc_eval": "~{qc_eval}"
        }
      }
    }
    EOF
  >>>

  output {
    File json_report = "~{samplename}_report.json"
  }
}