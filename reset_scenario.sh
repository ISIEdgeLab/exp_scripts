#!/usr/bin/env bash

PIDEID=${EXP}
FABFILE=tbutil_fabfile.py
POOLSIZE=15

while getopts :e:z:h opt; do
	case $opt in
		e) PIDEID=$OPTARG
			;;
        z) POOLSIZE=$OPTARG
            ;;
        *) echo $(basename $0) -e ProjID,ExpId \[-z poolsize\]
           echo
           echo If \$EXP exists in the environment it will be used for the -e argument.
           echo The -z argument controls how many processes are spawned to reset the scenario. 
           echo The active poolsize is ${POOLSIZE}
           exit 1
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

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

fab -f ${SCRIPTDIR}/${FABFILE} \
    --pool-size=${POOLSIZE} \
    initenv:pid=${PID},eid=${EID} \
    kill_click \
    kill_magi \
    kill_deterdash \
    start_click \
    start_magi \
    start_deterdash 
