version 1.0

task qc {
  input {
    Float r1_q30_trim
    Float r2_q30_trim
    Int  total_reads_trim
    Float coverage
    Float coverage_trim
    Int number_of_scaffolds
    String busco_summary
    Float genome_ratio
  }

  command <<<    
    # coverage
    if [ $(echo "~{coverage} < 40" | bc) -eq 1 ]; then
        echo "FAIL:Coverage<40X, " | tee -a QC_EVAL
    elif [ $(echo "~{coverage_trim} < 30" | bc) -eq 1 ]; then
        echo "WARN:Trimmed Coverage<30X, " | tee -a QC_EVAL
    fi
    # q30
    if [ $(echo "~{r1_q30_trim} < 90" | bc) -eq 1 ]; then
        echo "FAIL:R1 Q30<90%, " | tee -a QC_EVAL
    fi
    if [ $(echo "~{r2_q30_trim} < 70" | bc) -eq 1 ]; then
        echo "FAIL:R2 Q30<70%, " | tee -a QC_EVAL
    fi
    # reads
    if [ $(echo "~{total_reads_trim} < 1000000" | bc) -eq 1 ]; then
        echo "WARN:trimmed reads<1M, " | tee -a QC_EVAL
    fi
    # contigs
    if [ $(echo "~{number_of_scaffolds} > 200" | bc) -eq 1 ]; then
        echo "FAIL:Contigs>200, " | tee -a QC_EVAL
    fi
    # genome ratio
    if [ $(echo "~{genome_ratio} > 1.25" | bc) -eq 1 ]; then 
        echo "WARN:genome ratio>1.25, " | tee -a QC_EVAL
    elif [ $(echo "~{genome_ratio} < 0.75" | bc) -eq 1 ]; then 
        echo "WARN:genome ratio<0.75, " | tee -a QC_EVAL
    fi
    # completeness
    comp=$(echo ~{busco_summary} | cut -d "%" -f1 | cut -d ":" -f2)
    if [ $(echo "$comp < 97" | bc) -eq 1 ]; then
        echo "FAIL:genome_completeness<97%" | tee -a QC_EVAL
    fi
    # write pass if no fail
    if [ ! -f QC_EVAL ]; then
        echo "PASS" | tee QC_EVAL    
    fi
  >>>

  output {
    String qc_eval = read_string("QC_EVAL")
  }

  runtime {
    memory: "1 GB"
    cpu: 1
    docker: "kincekara/bash:alpine"
    disks: "local-disk 10 HDD"
    dx_instance_type: "mem1_ssd1_v2_x2" 
  }
}