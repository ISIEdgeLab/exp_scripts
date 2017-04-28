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
data = {}
c = 1
for line in out:
    tokens = line.strip("\n").split()
    if len(tokens) == 7 and tokens[1] == "via":
        data['if%d' % c] = tokens[4]
        data['if%d_16' % c] = tokens[0]
        data['if%d_gw' % c] = tokens[2]
        c = c + 1

config = template.substitute(**data)

fh = open(out_file, "w")
fh.write(config)
fh.close()
