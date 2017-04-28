#!/bin/bash

if [ "$1" == "" ]; then
	echo "Usage: $0 template_folder"
	exit -1
fi

cp /proj/edgect/templates/$1/enclave.routes /tmp
python /proj/edgect/exp_scripts/updateRoutes.py

