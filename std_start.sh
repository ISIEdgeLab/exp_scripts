#!/usr/bin/env bash

# get us some space to work with.
SPACEDEV=$(sudo fdisk -l | grep Empty | tail -1 | awk '{print $1}')
if grep ${SPACEDEV} /proc/mounts; then
    echo ${SPACEDEV} already mounted. Not remounting.
else
    echo Mounting /space
    sudo mkfs.ext4 ${SPACEDEV}
    sudo mkdir /space &> /dev/null
    sudo chmod 777 /space
    sudo mount ${SPACEDEV} /space
fi

# mount ZFS.
sudo mkdir /zfs &> /dev/null
sudo mount zfs:/zfs/edgect /zfs &> /dev/null
echo ZFS mounted on /zfs

# Run EdgeCT Magi everywhere.
echo Bootstrapping Magi.
sudo python /proj/edgect/magi/current/magi_bootstrap.py -fp /proj/edgect/magi/current

# per host type initialization.
HOST=$(hostname -s)
if [[ $HOST == control ]]; then 
    echo Initializing control node ${HOST}
    sudo python /proj/edgect/exp_scripts/fixHosts.py;
    touch /tmp/my_start
    sudo /share/deterdash/current/start_deterdash.sh
elif [[ $HOST == traf* ]]; then 
    echo Initializing traffic node ${HOST}
elif [[ $HOST == server* ]]; then 
    echo Initializing server node ${HOST}
elif [[ $HOST == ct* ]]; then 
    echo Initializing ct node ${HOST}
elif [[ $HOST == crypto* ]]; then 
    echo Initializing crypto node ${HOST}
else
    echo Initializing node ${HOST}
fi
