#!/usr/bin/env bash

# We need the reset magi script. Check first that we can find it. 
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
RESET=reset_magi.sh
FABFILE=tbutil_fabfile.py
POOLSIZE=15

if [[ ! -f ${SCRIPTDIR}/${RESET} ]]; then
	echo Could not locate $RESET script.
	exit 2
fi

# We only have a few extra args in addition to the reset args, if we don't recognize an arg, we'll assume it goes
# to reset_magi
while getopts :e:h opt; do
	case $opt in
	e) PIDEID=$OPTARG
	    ;;
        *)
            ;;
   esac
done

PID=$(echo ${PIDEID} | cut -d, -f1)
EID=$(echo ${PIDEID} | cut -d, -f2)

if [[ -z ${PID} ]]; then 
    PID=$(echo ${PIDEID} | cut -d/ -f1)
    EID=$(echo ${PIDEID} | cut -d/ -f2)
fi

if [[ -z ${PID} ]]; then 
    echo Error reading experiment name. Use -e pid,eid or set \$EXP in the environment.
    exit 2
fi

fab -f ${SCRIPTDIR}/${FABFILE} \
    --pool-size=${POOLSIZE} \
    initenv:pid=${PID},eid=${EID} \
    magi_log_to_space

${SCRIPTDIR}/${RESET} $@
