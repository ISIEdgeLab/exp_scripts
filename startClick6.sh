#!/bin/bash
sleep 60

cp /proj/edgect/templates/first-6.template /tmp/vrouter.template
python /proj/edgect/exp_scripts/updateClickConfig.py

sudo click-install -j 4 /tmp/vrouter.click 
