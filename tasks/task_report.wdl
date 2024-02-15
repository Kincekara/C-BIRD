version 1.0

task generate_report {
  input {
    String samplename
    File total_bases
    File taxon_report
    File mlst_report
    File amr_report
    File plasmid_report
    File fastp_report
    File busco_report
    File quast_report
    File taxid 
    File? mash_result
    File? blast_result
    Int genome_length
    String version
    String phix_ratio
    String footer_note = ""
    String docker = "kincekara/cbird-util:alpine-v1.1"    
  }

  command <<<
    # check mash results  
    if [ -f "~{mash_result}" ]
    then
      # catch taxon & find genome size
      taxon=$(awk '{print $1,$2}' ~{mash_result})
      datasets summary genome taxon "$taxon" --reference > gs.json

      # create summary report with mash
      if [ -f "~{blast_result}" ]
      # with blast
      then
        report_gen.py \
        -s ~{samplename} \
        -t ~{taxon_report} \
        -st ~{mlst_report} \
        -a ~{amr_report} \
        -p ~{plasmid_report} \
        -c "~{version}" \
        -m ~{mash_result} \
        -b ~{blast_result} \
        -f "~{footer_note}"
      # mash only
      else
        report_gen.py \
        -s ~{samplename} \
        -t ~{taxon_report} \
        -st ~{mlst_report} \
        -a ~{amr_report} \
        -p ~{plasmid_report} \
        -c "~{version}" \
        -m ~{mash_result} \
        -f "~{footer_note}"
      fi
    else
      # find genome size with bracken taxon id
      taxid=$(cat ~{taxid})
      datasets summary genome taxon "$taxid" --reference > gs.json
      
      # create summary report w/o mash      
      if [ -f "~{blast_result}" ]
      # blast only
      then
        report_gen.py \
        -s ~{samplename} \
        -t ~{taxon_report} \
        -st ~{mlst_report} \
        -a ~{amr_report} \
        -p ~{plasmid_report} \
        -c "~{version}" \
        -b ~{blast_result} \
        -f "~{footer_note}"
      # no mash or blast
      else
        report_gen.py \
        -s ~{samplename} \
        -t ~{taxon_report} \
        -st ~{mlst_report} \
        -a ~{amr_report} \
        -p ~{plasmid_report} \
        -c "~{version}" \
        -f "~{footer_note}"
      fi
    fi

    # alternative source for expected genome size
    jq -r '.reports[0].assembly_stats.total_sequence_length' gs.json > alt_gs.txt
    
    # calculate esimated coverage & genome ratio
    taxid=$(cat ~{taxid})
    est_coverage.py \
    ~{total_bases} \
    "$taxid" \
    alt_gs.txt \
    "~{genome_length}"    

    # create QC summary
    qc_report.py \
    ~{samplename} \
    ~{fastp_report} \
    ~{taxon_report} \
    ~{quast_report} \
    ~{busco_report} \
    "~{version}" \
    "~{phix_ratio}" \
    "COVERAGE" \
    "GENOME_RATIO"
  >>>

  output {
    File? clia_report = "~{samplename}_clia_report.html"
    File html_report = "~{samplename}_html_report.html"
    File qc_report = "~{samplename}_QC_summary.html"
    Float? sequencing_depth = read_float("COVERAGE")
    Float? sequencing_depth_trim = read_float("COVERAGE_TRIM")
    Float? genome_ratio = read_float("GENOME_RATIO")
    String cbird_util_docker = docker
  }

  runtime {
      docker: "~{docker}"
      memory: "8 GB"
      cpu: 4
      disks: "local-disk 100 SSD"
      preemptible:  0
  }
}