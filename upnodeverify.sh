#!/bin/sh

    STARTDIR="/proj/"`cat /var/containers/pid`"/exp/"`cat /var/containers/eid`"/startup"

    mkdir $STARTDIR
    date > $STARTDIR/`hostname`
