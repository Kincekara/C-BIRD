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
    String version
    String docker = "kincekara/cbird-util:alpine-v0.2"    
  }

  command <<<
    # create summary report
    report_gen.py \
    ~{samplename} \
    ~{taxon_report} \
    ~{mlst_report} \
    ~{amr_report} \
    ~{plasmid_report} \
    "~{version}"
    
    #alternative genome size
    taxid=$(<"~{taxid}")
    datasets summary genome taxon $taxid --reference > gs.json
    jq -r '.assemblies[0].assembly.seq_length' gs.json > alt_gs.txt
    
    # calculate esimated coverage
    est_coverage.py \
    ~{genome_stats} \
    ~{q30_bases} \
    ~{taxid} \
    alt_gs.txt

  >>>

  output {
    File txt_report = "~{samplename}_txt_report.txt"
    File html_report = "~{samplename}_html_report.html"
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