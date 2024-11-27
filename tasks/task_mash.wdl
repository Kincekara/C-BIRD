version 1.0

task predict_taxon {
  input {
    File assembly   
    File reference
    String samplename
    String docker = "kincekara/mash:2.3"
    Int? memory = 16
    Int? cpu = 4
  }

  command <<<
    # version
    mash --version > VERSION
    # screen assembly
    mash screen -p ~{cpu} ~{reference} ~{assembly} > ~{samplename}.mash.tsv
    # parse results
    sort -gr ~{samplename}.mash.tsv > ~{samplename}.mash.sorted.tsv
    taxon=$(awk -F "\t" 'NR==1 {print $6}' ~{samplename}.mash.sorted.tsv | sed 's/[^ ]* seqs] //' | sed 's/ \[.*//')
    echo $taxon > TAXON
    ratio=$(awk -F "\t" 'NR==1 {printf "%.2f\n",$1*100}' ~{samplename}.mash.sorted.tsv)
    echo $ratio > RATIO
    printf "$taxon\t$ratio\n" > ~{samplename}.top_taxon.tsv
  >>>

  output {
    String version = read_string("VERSION")
    File screen = "~{samplename}.mash.sorted.tsv"
    File top_taxon = "~{samplename}.top_taxon.tsv"
    String taxon = read_string("TAXON")
    Float ratio = read_float("RATIO")
    String mash_docker = docker
  }

  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}
