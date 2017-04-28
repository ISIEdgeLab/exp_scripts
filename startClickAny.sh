#!/bin/bash

if [ "$1" == "" ]; then
	echo "Usage: $0 template_folder"
	exit -1
fi

sudo apt-get install python-netaddr python-netifaces -y;

cp /proj/edgect/templates/$1/vrouter.template /tmp
python /proj/edgect/exp_scripts/updateClickConfig.py

sudo click-install -j 4 /tmp/vrouter.click 
