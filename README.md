# <img src="/files/c-bird.png" width=80>   C-BIRD  
**CT-PHL Bacterial Identification and Resistance Detection**
## Overview ##
C-BIRD is a pipeline that makes *de novo* assembly from Illumina paired-end reads and uses k-mer based approaches where they are available. It works on [Terra.Bio](https://terra.bio/) platform as well as any Linux machine which has [Cromwell](https://cromwell.readthedocs.io/en/stable/) or [miniwdl](https://miniwdl.readthedocs.io/en/latest/) workflow engines. As its name indicates, C-BIRD is designed for only rapid bacterial identification and antimicrobial resistance detection. 

## Purpose ##
The main goal of this project is to create a small, fast, and accurate workflow which can work in a cloud environment with high reproducibility and parallelization. C-BIRD uses minimalized docker containers for each pipeline step to achieve this goal. C-BIRD will be validated for a selected set of bacteria.

## Scope ##
C-BIRD has been created with a minimalistic approach. Producing clinically meaningful results and generating individual reports for each sample is within this project's scope. 
Any typing (except MLST) or further analysis is out of this project's scope. However, extra tools and programs may be added for validation purposes. 

## Installation ##
Terra users can add C-BIRD to their existing workspace in Terra via [Dockstore](https://dockstore.org/workflows/github.com/Kincekara/C-BIRD/cbird-workflow:main?tab=info).

C-BIRD deliberately avoids auto-updates of the necessary databases for strict control and validation purposes. The following databases and files should be installed or uploaded manually. Please check [wiki](https://github.com/Kincekara/C-BIRD/wiki) for detailed instructions.


| File | Comments |
| --- | --- |
| [Kraken2/Bracken database](https://benlangmead.github.io/aws-indexes/k2) | Standard 8 (required)|
| [Mash sketch](https://drive.google.com/file/d/1OH5UXvNnBWWLMNsKwz3QwGFB2RML8HV_/view?usp=share_link) | custom mash sketch (required) |
| Adapters fasta | Your sequencing adapters' list as a fasta file (optional)|
| Target genes fasta | Extra set of genes/proteins as a fasta file containing protein sequences (optional) |

## Workflow ##
C-BIRD uses Kraken2 and Braken for taxonomic profiling of reads, which serves as a contamination check. It can be expected to have a high abundance estimation from pure isolates in general. However, there are some exceptions due to the restrictions of databases, k-mer based approaches, and highly similar organisms. Results should be interpreted considering these factors. 

Mash is used to determine the identity of bacteria for selected genera with a custom mash sketch (Acinetobacter, Citrobacter, Enterobacter, Escherichia, Klebsiella, Kluyvera, Morganella, Proteus, Providencia, Pseudomonas, Raoultella, Salmonella, Serratia).

Detection of AMR genes depends on NCBI's AMRFinderPlus program and its database. 

The following programs and tools are used in the C-BIRD pipeline.

| Tools | Version | Comments |
| --- | --- | --- |
| [FastP](https://github.com/OpenGene/fastp) | 0.23.4 | QC, adapter removal, quality filtering and trimming |
| [BBTools](https://jgi.doe.gov/data-and-tools/software-tools/bbtools/) | 39.01 | phiX removal & optional normalization |
| [Kraken2](https://github.com/DerrickWood/kraken2) | 2.1.3 | Taxonomic profiling & contamination check |
| [Bracken](https://github.com/jenniferlu717/Bracken) | 2.9 | Abundance estimation |
| [SPAdes](https://github.com/ablab/spades) | 3.15.5 | *De novo* assembly |
| [Mash](https://github.com/marbl/Mash) | 2.3 | Bacterial identification |
| [QUAST](https://github.com/ablab/quast) | 5.2.0 | Genome assembly evaluation |
| [BUSCO](https://gitlab.com/ezlab/busco/-/tree/master) | 5.4.7 | Genomic data quality assesment |
| [mlst](https://github.com/tseemann/mlst) | 2.22.0 | MLST typing |
| [AMRFinderPlus](https://github.com/ncbi/amr) | 3.11.20 | AMR gene identification |
| [BLAST+](https://blast.ncbi.nlm.nih.gov/doc/blast-help/downloadblastdata.html)| 2.14.0 | Target gene search |
| [PlasmidFinder](https://bitbucket.org/genomicepidemiology/plasmidfinder/src/master/) | 2.1.6 | Plasmid detection |
| Cbird-Util | 1.0 | Individual summary report generation |

## Outputs ##
In addition to outputs generated in each step by the specific programs, C-BIRD creates additional summary reports in HTML for each sample. 

[Basic report](https://htmlpreview.github.io/?https://github.com/Kincekara/C-BIRD/blob/main/files/AR_0859_basic_report.html)  
[Advanced report](https://htmlpreview.github.io/?https://github.com/Kincekara/C-BIRD/blob/main/files/AR_0859_advanced_report.html)  
[QC report](https://htmlpreview.github.io/?https://github.com/Kincekara/C-BIRD/blob/main/files/AR_0859_QC_summary.html)

## Known issues ##
SPAdes may fail if an authorization domain is defined for the workspace on Terra.

## Additional Notes ##
C-BIRD includes modified and unmodified codes of [Theiagen's Public Health Bacterial Genomics](https://github.com/theiagen/public_health_bacterial_genomics) workflows. If you need a more sophisticated pipeline, please check Theiagen's TheiaProk workflow. 


