#!/usr/bin/env bash

PIDEID=${EXP}
FABFILE=tbutil_fabfile.py
POOLSIZE=15

MAGI_VERSION=current

while getopts :e:z:v:h opt; do
	case $opt in
		e) PIDEID=$OPTARG
			;;
        z) POOLSIZE=$OPTARG
            ;;
        v) MAGI_VERSION=$OPTARG
            ;;
        *) echo $(basename $0) -e ProjID,ExpId \[-z poolsize\] \[-v magi_version\]
           echo
           echo If \$EXP exists in the environment it will be used for the -e argument.
           echo 
           echo The -z argument controls how many processes are spawned to reset the scenario. 
           echo The active poolsize is ${POOLSIZE}
           echo 
           echo The optional -v argument if set will stop whatever version of magi is running, 
           echo and start up/install the specified version.
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

MAGI_DIR=/proj/edgect/magi/${MAGI_VERSION}

if [[ ! -d ${MAGI_DIR} ]]; then
    echo Error determining location of magi version \(${MAGI_VERSION}\) specified.
    echo -e "\t${MAGI_DIR} does not exist."
    exit 2
fi

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

fab -f ${SCRIPTDIR}/${FABFILE} \
    --pool-size=${POOLSIZE} \
    initenv:pid=${PID},eid=${EID} \
    kill_magi \
    start_magi:mdir="${MAGI_DIR}"
