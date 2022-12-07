version 1.0

import "../tasks/task_ncbi_datasets.wdl" as datasets
import "../tasks/task_bbtools.wdl" as bbtools

workflow estimate_inserts {

  meta {
  description: "C-BIRD auxiliary pipeline"
  }

  input {
    File read1
    File read2
    String samplename    
    String taxon
  }

  call datasets.fetch_reference {
    input:
      samplename = samplename,      
      taxon = taxon
  }

  call bbtools.insert_size_dist {
    input:
      read1 = read1,
      read2 = read2,
      samplename = samplename,
      reference = fetch_reference.reference
  }

  output {
    File insert_size_hist = insert_size_dist.insert_size_hist
    File insert_size_plot = insert_size_dist.insert_size_plot 
    Int median_insert_size = insert_size_dist.median_insert_size
  }
}