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
    File checkm2_report
    File quast_report
    File taxid 
    File? mash_result
    File? blast_result
    Int genome_length
    String version
    String phix_ratio
    String footer_note = ""
    String? labid
    String analysis_date
    File? logo1
    File? logo2
    File? disclaimer
    String? line1
    String? line2
    String? line3
    String? line4
    String? line5
    String? line6
    String docker = "kincekara/cbird-util:2.0"    
  }

  command <<<
    # check mash results  
    if [ -f "~{mash_result}" ]
    then
      # catch taxon & find genome size
      taxon=$(awk '{print $1,$2}' ~{mash_result})
      percent=$(awk '{print $3}' ~{mash_result})
      datasets summary genome taxon "$taxon" --reference > gs.json

      #  create plain report
      if [ -z "~{labid}" ]
      then
        plain_report.py \
        -d "~{analysis_date}" \
        -i "~{labid}" \
        -o "$taxon" \
        -p "$percent" \
        -a ~{amr_report} \
        -n ~{disclaimer} \
        -l ~{logo1} \
        -r ~{logo2} \
        --hl1 "~{line1}"\
        --hl2 "~{line2}" \
        --hl3 "~{line3}" \
        --hl4 "~{line4}" \
        --hl5 "~{line5}" \
        --hl6 "~{line6}"
      else
        echo "No labid is provided!"
      fi

      # create summary report with mash
      if [ -f "~{blast_result}" ]
      # with blast
      then
        html_report.py \
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
        html_report.py \
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
        html_report.py \
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
        html_report.py \
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
    ~{checkm2_report} \
    "~{version}" \
    "~{phix_ratio}" \
    "COVERAGE" \
    "GENOME_RATIO"
  >>>

  output {
    File? plain_report = "~{labid}_report.docx"
    File basic_report = "~{samplename}_basic_report.html"
    File extended_report = "~{samplename}_extended_report.html"
    File qc_report = "~{samplename}_QC_summary.html"
    Float sequencing_depth = read_float("COVERAGE")
    Float sequencing_depth_trim = read_float("COVERAGE_TRIM")
    Float genome_ratio = read_float("GENOME_RATIO")
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