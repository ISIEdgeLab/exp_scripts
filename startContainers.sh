#!/usr/bin/env bash

IGNORE_NODES="tbdelay tunnel external"
SSHARGS="-o ConnectTimeout=1 -o PasswordAuthentication=no -o StrictHostKeyChecking=no"

while getopts :e:i:h opt; do
	case $opt in
		e) EXP=$OPTARG
			;;
        i) IGNORE_NODES="$IGNORE_NODES $OPTARG"
            ;;
		h)
			echo $(basename $0) [-pe] command
			echo -e "\t-e run on nodes in experiment,group. e.g. MyGroup,MyExperiment"
			exit 1
            ;;
        *)
            echo Unknown argument. See -h for usage.
            exit 1
            ;;
	esac
done

if [[ ${EXP} == "" ]]; then
    echo You must set \$EXP or use the -e argument.
    exit 1
fi

GID=$(echo $EXP | cut -d, -f1)
EID=$(echo $EXP | cut -d, -f2)
CMD="sudo umount /vz; sudo /share/containers/setup/hv/bootstrap /proj/${GID}/exp/${EID}/containers/site.conf"

nodes=$(/usr/testbed/bin/node_list -e ${EXP} | sort)
if [[ ${nodes} == "" ]]; then
    echo Unable to find nodes in experiment ${EXP}. Is is swapped in? 1>&2
    exit 1
fi

error=0
for n in ${nodes}; do 
    # skip nodes that should not execute the command
    skip=0
    for ignore_node in ${IGNORE_NODES}; do 
        if [[ $n == *${ignore_node}* ]]; then
            skip=1
            break
        fi
    done
    if [[ $skip -eq 1 ]]; then
        continue
    fi 
	echo Starting containers on ${n}.
	ssh ${SSHARGS} -n ${n} "${CMD}" &
	if [[ $? -ne 0 ]]; then 
	    echo "**********ERROR running connecting on ${n}" 1>&2
	    (( error++ ))
	fi
done

# wait for bg processes to complete.
wait

if [[ ${error} -gt 0 ]]; then
	echo "**** WARNING ****" 1>&2 
	echo "There were ${error} errors running commands on the experiment nodes." 1>&2 
fi
