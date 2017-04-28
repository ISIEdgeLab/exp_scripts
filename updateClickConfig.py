#!/bin/python
import sys
import subprocess
from string import Template

template_file = "/tmp/vrouter.template"
out_file = "/tmp/vrouter.click"

try:
    template = Template(open(template_file).read())
except Exception as e:
    sys.exit(1)

(output, error) = subprocess.Popen(["ip", "route"], stdout = subprocess.PIPE, stderr = subprocess.PIPE).communicate()

out = output.splitlines()
ifs = []
if_16s = []
if_gws = []
for line in out:
    tokens = line.strip("\n").split()
    if len(tokens) == 7 and tokens[1] == "via":
        ifs.append(tokens[4])
        if_16s.append(tokens[0])
        if_gws.append(tokens[2])


config = template.substitute(if1 = ifs[0], if2 = ifs[1], if3 = ifs[2], if1_16 = if_16s[0], if2_16 = if_16s[1], if3_16 = if_16s[2], if1_gw = if_gws[0], if2_gw = if_gws[1], if3_gw = if_gws[2])

fh = open(out_file, "w")
fh.write(config)
fh.close()
