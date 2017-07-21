#!/usr/bin/env bash

PIDEID=${EXP}
FABFILE=tbutil_fabfile.py
POOLSIZE=15
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYENV=${SCRIPTDIR}/edgect_pyenv
MAGI_VERSION=current
MAGI_DIR=/proj/edgect/magi/${MAGI_VERSION}

while getopts :e:z:v:h opt; do
	case $opt in
		e) PIDEID=$OPTARG
			;;
        z) POOLSIZE=$OPTARG
            ;;
        v) MAGI_VERSION=$OPTARG
            ;;
        *) echo $(basename $0) -e ProjID,ExpId \[-z poolsize\] \[-v magi_version\] \[module module ...\]
           echo
           echo If \$EXP exists in the environment it will be used for the -e argument.
           echo 
           echo The -z argument controls how many processes are spawned to reset the scenario. 
           echo The active poolsize is ${POOLSIZE}
           echo 
           echo The optional -v argument if set will stop whatever version of magi is running, 
           echo and start up/install the specified version.
           echo
           echo Individual modules can be reset using this script as well. If given on the command line
           echo only those modules will be reset and not the whole scenario. Supported modules are
           echo \"magi\", \"deterdash\", and \"click\". If no module is specified, all will be reset. If 
           echo any are specified, only those will be reset, e.g. \"$(basename $0) magi click\" will 
           echo restart magi and click, but not deterdash. 
           echo
           exit 1
           ;;
   esac
done

shift "$((OPTIND - 1))"

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

if [[ ! -d ${MAGI_DIR} ]]; then
    echo Error determining location of magi version \(${MAGI_VERSION}\) specified.
    echo -e "\t${MAGI_DIR} does not exist."
    exit 2
fi

. ${PYENV}/bin/activate &>/dev/null   # grab our local python env including fabric.

# default is to restart everything. Individual things can be set on the command line though.
kills="kill_magi kill_deterdash kill_click"
starts="start_click start_magi:mdir=${MAGI_DIR} start_deterdash"
if [[ $# -ne 0 ]]; then
    kills=
    starts=
    for arg in $*; do 
        case $arg in
            magi)
                kills="${kills} kill_${arg}"
                starts="${starts} start_${arg}:mdir=${MAGI_DIR}"
                ;;
            click|deterdash)
                kills="${kills} kill_${arg}"
                starts="${starts} start_${arg}"
                ;;
            *) echo I don\'t know how to reset ${arg}, ignoring.
                ;;
        esac
    done
fi

fab -f ${SCRIPTDIR}/${FABFILE} \
    --pool-size=${POOLSIZE} \
    initenv:pid=${PID},eid=${EID} \
    ${kills} \
    ${starts}
