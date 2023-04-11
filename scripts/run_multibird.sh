#!/bin/bash
#-------------------------------------------------#
# MultiBIRD runner script v0.1                    #
# Author: Kutluhan Incekara (kutluinct@gmail.com) #
# 2023-03-07                                      #
#-------------------------------------------------#

# Please define paths and parameters before using !!
config="/path_to/cwl.config"
cromwell="/path_to/cromwell-XX.jar"
cbird_path="$HOME"
input_json="multibird_input.json"
# conda_env="python3"

# run multibird
echo ' ᕙ(`▿´)ᕗ '
echo "Running multiBIRD..."
java -Dconfig.file=$config -jar $cromwell run $cbird_path/C-BIRD/workflows/wf_multi_bird.wdl -i $input_json |& tee multibird.log

# parse results
echo "The run finished! Parsing results..."
# eval "$(conda shell.bash hook)"
# conda activate $conda_env
python3 ./multibird_parser.py
# conda deactivate

echo '（‐＾▽＾‐）'
echo "Finished! Bye... "

