#!/bin/bash

sudo ethtool -s eth3 speed 10000 duplex full
sudo ethtool -s eth4 speed 10000 duplex full
sudo ethtool -s eth5 speed 10000 duplex full

sleep 30
