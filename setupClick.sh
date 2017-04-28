#!/bin/bash

k_v=$(uname -r)
sys_map="/boot/System.map-$k_v"
sudo chmod go+r $sys_map

cp /proj/edgect/tarfiles/click.tgz /tmp
cd /tmp
tar -xzf click.tgz
cd click
./configure --enable-linuxmodule --enable-etherswitch --enable-multithread --enable-intel-cpu --enable-local
make
sudo make install

cp /proj/edgect/templates/vrouter.template /tmp
python /proj/edgect/exp_scripts/updateClickConfig.py

sudo click-install /tmp/vrouter.click 
