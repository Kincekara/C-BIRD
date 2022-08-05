version 1.0

task fastp_pe {
  input {
    File read1
    File read2
    File adapters
    String docker = "kincekara/fastp:0.23.2"
    String samplename
    Int? leading = 1
    Int? front_mean_quality = 10
    Int? trailing = 1
    Int? tail_mean_quality = 10
    Int? minlen = 50
    Int? window_size = 4
    Int? right_mean_quality = 20
    Int? thread = 4
    }

command <<<
    fastp \
    -i ~{read1} \
    -I ~{read2} \
    -o ~{samplename}_R1_trim.fastq.gz \
    -O ~{samplename}_R2_trim.fastq.gz \
    --adapter_fasta ~{adapters} \
    --cut_front_window_size ~{leading} \
    --cut_front_mean_quality ~{front_mean_quality} \
    -3 \
    --cut_tail_window_size ~{trailing} \
    --cut_tail_mean_quality ~{tail_mean_quality} \
    -r \
    --cut_right_window_size ~{window_size} \
    --cut_right_mean_quality ~{right_mean_quality} \
    --length_required ~{minlen} \
    --thread ~{thread} \
    -h ~{samplename}_fastp.html

    # parse output
    jq '.summary.fastp_version' fastp.json > VERSION
    jq '.summary.before_filtering.q30_rate' fastp.json > Q30_RAW
    jq '.summary.after_filtering.q30_rate' fastp.json > Q30_TRIM
    jq '.summary.after_filtering.q30_bases' fastp.json > q30_bases.txt
>>>

output {
    File read1_trimmed = "~{samplename}_R1_trim.fastq.gz"
    File read2_trimmed = "~{samplename}_R2_trim.fastq.gz"
    File fastp_report = "~{samplename}_fastp.html"
    String fastp_version = read_string("VERSION")
    Float q30_raw = read_float("Q30_RAW")
    Float q30_trim = read_float("Q30_TRIM")
    File q30_bases = "q30_bases.txt"
    String fastp_docker = docker
    }

runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible:  0
    }
}