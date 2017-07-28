#!/usr/bin/env bash

TEMPLATE_DIR=/proj/edgect/templates/

if test $# -eq 0; then
	echo "ERROR: Not enough arguments given."
	$0 -h
	exit 1
fi

TEMPLATE_GIVEN=false

while test $# -gt 0; do
	case "$1" in
		-h|--help)
			echo "$0: Install necessary packages, configure click and start DPDK click"
			echo "Usage: $0 [-p|--path path_to_templates] template_name"
			echo -e "\t-h, --help\tProduce this help message and exit."
			echo -e "\t-p, --path\tLook for Click  templates in this directory."
			echo -e "\t\t\tWithout this option, script will search for templates in ${TEMPLATE_DIR}"
			exit 0
			;;
		-p|--path)
			shift
			if test $# -gt 0; then
				TEMPLATE_DIR=$1
			else
				echo "ERROR: No path given to -p|--path option"
				exit 1
			fi
			shift
			;;
		*)
			if $TEMPLATE_GIVEN; then
				echo "ERROR: Given multiple templates?"
				$0 -h
				exit 1
			fi
			TEMPLATE_GIVEN=true
			TEMPLATE=$1
			shift						
			;;
	esac
done

if ! $TEMPLATE_GIVEN; then
	echo "ERROR: No template given."
	exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
	echo "ERROR: No such directory: $TEMPLATE_DIR"
	exit 1
fi

if [ ! -d "$TEMPLATE_DIR/$TEMPLATE" ]; then
	echo "ERROR: No such template directory found: $TEMPLATE_DIR/$TEMPLATE"
	exit 1
fi

if [ ! -f "$TEMPLATE_DIR/$TEMPLATE/vrouter.template" ]; then
	echo "ERROR: Click template ($TEMPLATE_DIR/$TEMPLATE/vrouter.template) not found."
	exit 1
fi

echo "INFO: Given template $TEMPLATE and dir $TEMPLATE_DIR"

sudo apt-get update
sudo apt-get install python-netaddr python-netifaces -y;

cp $TEMPLATE_DIR/$TEMPLATE/vrouter.template /tmp
python /proj/edgect/exp_scripts/updateClickConfig.py

# kill possibily lingering instances.
sudo pkill click &> /dev/null
sudo rm -f /click &> /dev/null

sudo click --dpdk -c 0xffffff -n 4 -- -u /click /tmp/vrouter.click &
