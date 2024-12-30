version 1.0

task predict_taxon {
  input {
    File assembly   
    File? reference
    String samplename
    String docker = "kincekara/mash:2.3-cbird-v2.0"
    Int? memory = 16
    Int? cpu = 4
  }

  command <<<
    # version
    mash --version > VERSION

    # screen assembly
    if [ -f "~{reference}" ]; then
      mash screen -p ~{cpu} ~{reference} ~{assembly} > ~{samplename}.mash.tsv
    else
      mash screen -p ~{cpu} /cbird-v2.0-lite.msh ~{assembly} > ~{samplename}.mash.tsv
    fi    

    # parse results
    sort -gr ~{samplename}.mash.tsv > ~{samplename}.mash.sorted.tsv
    top=$(awk -F "\t" 'NR==1 {print $6}' ~{samplename}.mash.sorted.tsv)
    if [[ "$top" =~ ^\[[0-9]+[[:space:]]seqs\]+ ]]; then
      candidate=$(echo "$top" | cut -d ' ' -f 4,5,6,7)
    else
      candidate=$(echo "$top" | cut -d ' ' -f 2,3,4,5)
    fi
    # check subspecies
    if [[ $(echo "$candidate" | awk '{print $3}') == "subsp." ]]; then
      taxon="$candidate"
    else
      taxon=$(echo "$candidate" | cut -d ' ' -f 1,2)
    fi
    echo $taxon > TAXON
    # find ratio
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
