#!/bin/bash

if [ "$1" == "" ]; then
	echo "Usage: $0 template_folder"
	exit -1
fi

sudo apt-get install python-netaddr python-netifaces -y;

cp /proj/edgect/templates/$1/vrouter.template /tmp
python /proj/edgect/exp_scripts/updateClickConfig.py

# kill possibily lingering instances.
sudo pkill click &> /dev/null
sudo rm -f /click &> /dev/null

sudo click --dpdk -c 0xffffff -n 4 -- -u /click /tmp/vrouter.click &
