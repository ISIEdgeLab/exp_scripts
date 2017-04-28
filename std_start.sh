#!/usr/bin/env bash

SPACEDEV=$(sudo fdisk -l | grep Empty | tail -1 | awk '{print $1}')

# get us some space to work with.
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

# Run Magi everywhere.
echo Bootstrapping Magi.
sudo python /proj/edgect/magi/current/magi_bootstrap.py -fp /proj/edgect/magi/current

HOST=$(hostname -s)
if [[ $HOST -eq control ]]; then 
    sudo python /proj/edgect/exp_scripts/fixHosts.py;
    touch /tmp/my_start
    sudo /share/deterdash/current/start_deterdash.sh
fi
