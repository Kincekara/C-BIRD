# -*- coding: utf-8 -*-
"""
MultiBIRD Output Parser
Created on Thu Feb  9 08:29:46 2023
@author: Kutluhan Incekara
"""
import json
import pandas as pd
import time
import re

file = "./multibird.log"

def samplename(path):
    m = re.match(".*\/execution\/(.*)_fastp.html", path)
    return m.group(1)

# find outputs in log
with open(file, "r") as log:
    lines = log.readlines()

start = 0
stop = 0    
for i in range(len(lines)):
    if '  "outputs": {' in lines[i]:
        start = i
    if '"id":' in lines[i]:
        stop = i
                
# extract json output    
output = ""
for i in range(start-1,stop+2):
    output += lines[i]

# json to df       
x = json.loads(output)
df = pd.DataFrame.from_dict(x['outputs'])

# organize df
dt ={}
for name in df.columns:
    new = name.replace("multibird.cbird_workflow.", "")
    dt[name]=new

df = df.rename(columns=dt) 
   
df["lab_id"] = df["fastp_report"].apply(samplename)
df = df.set_index("lab_id")
df = df.reindex(sorted(df.columns), axis=1)

# write tab seperated txt
timestr = time.strftime("%y%m%d.%H%M%S")
df.to_csv("multibird." + timestr + ".txt", index=True, sep="\t")