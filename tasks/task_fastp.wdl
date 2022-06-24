version 1.0

task fastp_pe {
  input {
    File read1
    File read2
    File adapters
    String docker = "quay.io/biocontainers/fastp:0.20.1--h8b12597_0"
    String samplename
    Int? leading = 1
    Int? front_mean_quality = 10
    Int? trailing = 1
    Int? tail_mean_quality = 10
    Int? minlen = 36
    Int? window_size = 4
    Int? right_mean_quality = 15
    Int? thread = 4

    }

command <<<
    fastp \
    -i ~{read1} \
    -I ~{read2} \
    -o ~{samplename}_R1_trim.fastq.gz \
    -O ~{samplename}_R2_trim.fastq.gz \
    --cut_front_window_size ~{leading} \
    --cut_front_mean_quality ~{front_mean_quality} \
    -3 \
    --cut_tail_window_size ~{trailing} \
    --cut_tail_mean_quality ~{tail_mean_quality} \
    -r \
    --cut_right_window_size ~{window_size} \
    --cut_right_mean_quality ~{right_mean_quality} \
    --length_required ~{minlen} \
    --thread ~{thread}
>>>

output {
    File read1_trimmed = "~{samplename}_R1_trim.fastq.gz"
    File read2_trimmed = "~{samplename}_R2_trim.fastq.gz"
    File fastp_report = "fastp.html"
    File fastp_json = "fastp.json"
    }

runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible:  0
    }
}