version 1.0

task generate_report {
  input {
    String samplename
    File genome_stats
    File q30_bases
    File taxon_report
    File mlst_report
    File amr_report
    File plasmid_report
    File taxid
    String docker = "kincekara/cbird-util:alpine"    
  }

  command <<<
    # create summary report
    report_gen.py \
    ~{samplename} \
    ~{taxon_report} \
    ~{mlst_report} \
    ~{amr_report} \
    ~{plasmid_report} \
    > ~{samplename}_summary_report.txt

    #alternative genome size
    taxid=$(<"~{taxid}")
    datasets summary genome taxon $taxid > gs.json
    jq -r '.assemblies[0].assembly.seq_length' gs.json > alt_gs.txt
    
    # calculate esimated coverage
    est_coverage.py \
    ~{genome_stats} \
    ~{q30_bases} \
    ~{taxid} \
    alt_gs.txt

  >>>

  output {
    File final_report = "~{samplename}_summary_report.txt"
    String sequencing_coverage = read_string("COVERAGE")
  }

  runtime {
      docker: "~{docker}"
      memory: "8 GB"
      cpu: 4
      disks: "local-disk 100 SSD"
      preemptible:  0
  }
}