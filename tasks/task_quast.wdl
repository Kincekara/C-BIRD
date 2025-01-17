version 1.0

task quast {
  input {
    File assembly
    String samplename
    String docker= "staphb/quast:5.3.0-slim"
  }
  command <<<
    # version
    quast.py --version | cut -d "," -f 1 | tee VERSION

    quast.py ~{assembly} -o .
    mv report.tsv ~{samplename}_report.tsv
    
    python3 <<CODE
    import csv
    #grab output genome length and number contigs by column header
    with open("~{samplename}_report.tsv",'r') as tsv_file:
      tsv_reader = csv.reader(tsv_file, delimiter="\t")
      for line in tsv_reader:
          if "Total length" in line[0]:
            with open("GENOME_LENGTH", 'wt') as genome_length:
              genome_length.write(line[1])
          if "# contigs" in line[0]:
            with open("NUMBER_CONTIGS", 'wt') as number_contigs:
              number_contigs.write(line[1])
          if "N50" in line[0]:
            with open("N50_VALUE", 'wt') as n50_value:
              n50_value.write(line[1])
          if "L90" in line[0]:
            with open("L90_VALUE", 'wt') as l90_value:
              l90_value.write(line[1])
          if "GC (%)" in line[0]:
            with open("GC_CONTENT", 'wt') as gc_content:
              gc_content.write(line[1])
    CODE
  >>>

  output {
    File quast_report = "${samplename}_report.tsv"
    String version = read_string("VERSION")
    Int genome_length = read_int("GENOME_LENGTH")
    Int number_contigs = read_int("NUMBER_CONTIGS")
    Int n50_value = read_int("N50_VALUE")
    Int l90_value = read_int("L90_VALUE")
    String quast_docker = docker
    Float gc_content = read_float("GC_CONTENT")
  }
  
  runtime {
    docker:  "~{docker}"
    memory:  "1 GB"
    cpu:   1
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}
