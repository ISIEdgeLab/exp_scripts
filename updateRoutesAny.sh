#!/bin/bash

if [ "$1" == "" ]; then
	echo "Usage: $0 template_folder"
	exit -1
fi

DIR=$1
shift 1

cp /proj/edgect/templates/$DIR/enclave.routes /tmp
sudo python /proj/edgect/exp_scripts/updateRoutes.py $@

