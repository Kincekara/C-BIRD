# <img src="/c-bird.png" width=80>   C-BIRD  
**CT-PHL Bacterial Identification and Resistance Detection**

:construction: This workflow is currently in the active development and testing stage.:hatching_chick: 

:rotating_light: It has not been validated for any species yet. Please use it with caution! :rotating_light:

## Overview ##
C-BIRD is an agnostic pipeline that makes *de novo* assembly from Illumina paired-end reads and uses k-mer based approaches where is available. It works on [Terra.Bio](https://terra.bio/) platform as well as any Linux machine which has [Cromwell](https://cromwell.readthedocs.io/en/stable/) or [miniwdl](https://miniwdl.readthedocs.io/en/latest/) workflow engines. As its name indicates, C-BIRD is designed for only rapid bacterial identification and antimicrobial resistance detection. 

## Purpose ##
The main goal of this project is to create a small, fast, and accurate workflow which can work in a cloud environment with high reproducibility and parallelization. To achieve this goal, C-BIRD uses minimalized docker containers for each step of the pipeline. C-BIRD will be validated for a selected set of bacteria.

## Scope ##
C-BIRD has been created with a minimalistic approach. Producing clinically meaningful results and generating individual reports for each sample is within the scope of this project. 
Any typing (except MLST) or further analysis is out of the scope of this project. However, extra tools and programs may be added for validation purposes. 

## Installation ##
Please check [Dockstore](https://dockstore.org/workflows/github.com/Kincekara/C-BIRD/cbird-workflow:main?tab=info) for Terra installation.

C-BIRD deliberately avoids auto-updates of the necessary databases for strict control and validation purposes. The following databases and files should be installed or uploaded manually.

| File | Comments |
| --- | --- |
| Adapters fasta | Your sequencing adapters' list as a fasta file |
| [Kraken2/Bracken database](https://benlangmead.github.io/aws-indexes/k2) | Standard 8 |
| [BUSCO database](https://busco-data.ezlab.org/v5/data/lineages/bacteria_odb10.2020-03-06.tar.gz)| bacteria_odb10 |
| [NCBI’s AmrFinderPlus database](https://ftp.ncbi.nlm.nih.gov/pathogen/Antimicrobial_resistance/AMRFinderPlus/database/latest/) | It should be compressed as tar.gz. Alternatively, it can be obtained via AmrFinderPlus |
| [PlasmidFinder database]( https://bitbucket.org/genomicepidemiology/plasmidfinder_db/src/master/) | It should be compressed as tar.gz |
| [NCBI’s genome statistics](https://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/species_genome_size.txt.gz) | Use decompressed text file |

## Workflow ##
C-BIRD relies on Kraken2 and Braken for microorganism identification and contamination check. It can be expected to get over 99% abundance estimation from pure isolates in general. However, there are some exceptions due to the restrictions of databases and k-mer based approaches. Results should be interpreted considering these factors. 

Detection of AMR genes depends on NCBI’s AMRFinderPlus program and its database. 

The following programs and tools are used in C-BIRD pipeline.

| Tools | Version | Comments |
| --- | --- | --- |
| FastP | 0.23.2 | QC, adapter removal, quality filtering and trimming |
| BBDuk | 38.98 | phiX removal |
| Kraken2 | 2.1.2 | Species identification |
| Bracken | 2.7 | Abundance estimation |
| SPAdes | 3.15.5 | *De novo* assembly |
| QUAST | 5.0.2 | Genome assembly evaluation |
| BUSCO | 5.3.2 | Genomic data quality assesment |
| mlst | 2.22.0 | MLST typing |
| AMRFinderPlus | 3.10.40 | AMR gene identification |
| PlasmidFinder | 2.1.6 | Plasmid detection |
| Cbird-Util | 0.2 | Individual summary report generation |

## Outputs ##
In addition to outputs generated in each step by the specific programs, C-CIRD creates additional summary reports in html and text format for each sample. 

[Example report](https://htmlpreview.github.io/?https://github.com/Kincekara/C-BIRD/blob/main/files/example_report.html)

## Known issues ##
SPAdes may fail if an authorization domain is defined for the workspace on Terra.

## Additional Notes ##
C-BIRD includes modified and unmodified codes of [Theiagen’s Public Health Bacterial Genomics](https://github.com/theiagen/public_health_bacterial_genomics) workflows. If you need a more sophisticated pipeline, please check Theiagen’s TheiaProk workflow. 


