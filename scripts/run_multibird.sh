#!/bin/bash
#-------------------------------------------------#
# MultiBIRD runner script v0.1                    #
# Author: Kutluhan Incekara (kutluinct@gmail.com) #
# 2023-03-07                                      #
#-------------------------------------------------#

# define paths & params
config="/home/incekara/bin/cwl.config"
cromwell="/home/incekara/bin/cromwell-84.jar"
cbird="/home/incekara/"
input_json="multi.json"

# run multibird
echo ' ᕙ(`▿´)ᕗ '
echo "Running multiBIRD..."
java -Dconfig.file=$config -jar $cromwell run $cbird/C-BIRD/workflows/wf_multi_bird.wdl -i $input_json |& tee multibird.log

# parse results
echo "The run finished! Parsing results..."
eval "$(conda shell.bash hook)"
conda activate python3
python3 ./multibird_parser.py
conda deactivate

echo '（‐＾▽＾‐）'
echo "Finished! Bye... "

