#!/bin/python
import sys
import subprocess
from string import Template

template_file = "/tmp/vrouter.template"
out_file = "/tmp/vrouter.click"

try:
    template = Template(open(template_file).read())
    tf = open(template_file, "r")
except Exception as e:
    sys.exit(1)

arpless = False
for line in tf:
	if "friend" in line:
		arpless = True
		break
tf.close()

(output, error) = subprocess.Popen(["ip", "route"], stdout = subprocess.PIPE, stderr = subprocess.PIPE).communicate()

out = output.splitlines()
data = {}
gws = []
ifs = []
c = 1
for line in out:
    tokens = line.strip("\n").split()
    if len(tokens) == 7 and tokens[1] == "via":
        data['if%d' % c] = tokens[4]
        data['if%d_16' % c] = tokens[0]
        data['if%d_gw' % c] = tokens[2]
        gws.append(tokens[2]) 
        ifs.append(tokens[4])
        c = c + 1

if arpless:
    dev_null = open('/dev/null', 'w')
    for gw in gws:
        cmd = 'ping -c 1 %s' % gw
        subprocess.Popen(cmd.split(), stdout=dev_null)
        
    (output, error) = subprocess.Popen(["arp", "-a"], stdout = subprocess.PIPE, stderr = subprocess.PIPE).communicate()
	
    out = output.splitlines()
    for line in out:
        tokens = line.strip("\n").split()
        if len(tokens) == 7 and tokens[0] != '?':
            if tokens[-1] in ifs:
                data['if%d_friend' % (ifs.index(tokens[-1]) + 1)] = tokens[3]	

config = template.substitute(**data)

fh = open(out_file, "w")
fh.write(config)
fh.close()
