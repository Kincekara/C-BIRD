version 1.0

task fastp_pe {
  input {
    File read1
    File read2
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
    --detect_adapter_for_pe \
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
    jq -r '.summary.fastp_version' fastp.json > VERSION
    jq '.summary.before_filtering.total_reads' fastp.json > TOTAL_READS
    jq '.summary.before_filtering.q30_bases' fastp.json > q30_bases.txt
    jq '.read1_before_filtering.total_reads' fastp.json > R1_READS    
    jq '.read2_before_filtering.total_reads' fastp.json > R2_READS
    r1_q30=$(jq '.read1_before_filtering.q30_bases' fastp.json)
    r1_total=$(jq '.read1_before_filtering.total_bases' fastp.json)
    echo "$r1_q30 $r1_total" | awk '{printf "%.6f", $1/$2 }' > R1_Q30_RAW
    r2_q30=$(jq '.read2_before_filtering.q30_bases' fastp.json)
    r2_total=$(jq '.read2_before_filtering.total_bases' fastp.json)
    echo "$r2_q30 $r2_total" | awk '{printf "%.6f", $1/$2 }' > R2_Q30_RAW
    r1_q30_trim=$(jq '.read1_after_filtering.q30_bases' fastp.json)
    r1_total_trim=$(jq '.read1_after_filtering.total_bases' fastp.json)
    echo "$r1_q30_trim $r1_total_trim" | awk '{printf "%.6f", $1/$2 }' > R1_Q30_TRIM
    r2_q30_trim=$(jq '.read2_after_filtering.q30_bases' fastp.json)
    r2_total_trim=$(jq '.read2_after_filtering.total_bases' fastp.json)
    echo "$r2_q30_trim $r2_total_trim" | awk '{printf "%.6f", $1/$2 }' > R2_Q30_TRIM

>>>

output {
    File read1_trimmed = "~{samplename}_R1_trim.fastq.gz"
    File read2_trimmed = "~{samplename}_R2_trim.fastq.gz"
    File fastp_report = "~{samplename}_fastp.html"
    String fastp_version = read_string("VERSION")
    File q30_bases = "q30_bases.txt"
    Int total_reads = read_int("TOTAL_READS")
    Int r1_reads = read_int("R1_READS")
    Int r2_reads = read_int("R2_READS")
    Float r1_q30_raw = read_float("R1_Q30_RAW")
    Float r2_q30_raw = read_float("R2_Q30_RAW")
    Float r1_q30_trim = read_float("R1_Q30_TRIM")
    Float r2_q30_trim = read_float("R2_Q30_TRIM")
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