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
    String docker = "kincekara/cbird-util:alpine"    
  }

  command <<<
    #alternative genome size
    taxid = $(awk 'NR==1; NR>1 {print $0 | "sort -k 7nr"}' ~{taxon_report} | awk 'NR==2 {print $3}')
    datasets summary genome taxon $taxid > gs.json
    jq '.assemblies[0].assembly.seq_length' gs.json > alt_gs.txt

    report_gen.py \
    ~{samplename} \
    ~{genome_stats} \
    ~{q30_bases} \
    ~{taxon_report} \
    ~{mlst_report} \
    ~{amr_report} \
    ~{plasmid_report} \
    alt_gs.txt \
    > ~{samplename}_final_report.txt
  >>>

  output {
    File final_report = "~{samplename}_final_report.txt"
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