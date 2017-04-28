#!/bin/python
import subprocess

fh = open("/etc/hosts", "r")
out_fh = open("/etc/new_hosts", "w")

line = fh.readline()

tokens = line.strip("\n").split()
skip = False
for token in tokens:
    if token == "control":
        skip = True
        break

if not skip:
    line = line.strip("\n")
    line = "%s control\n" % line

out_fh.write(line)
out_fh.write(fh.read())

fh.close()
out_fh.close()

subprocess.call(["cp", "/etc/hosts", "/etc/old_hosts"])
subprocess.call(["cp", "/etc/new_hosts", "/etc/hosts"])
