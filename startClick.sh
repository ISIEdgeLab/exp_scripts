#!/bin/bash
sleep 60

cp /proj/edgect/templates/vrouter.template /tmp
python /proj/edgect/exp_scripts/updateClickConfig.py

sudo click-install /tmp/vrouter.click 
