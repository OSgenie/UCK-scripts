#!/bin/bash
# Deletes current iso working directory.
sudo rm -r /work/live/*
sudo rm -r /work/install/*
# Tnstalls default settings.
cd UCK-scripts/
git pull
sudo ./install-UCK-scripts-to-crontab.sh
#sudo shutdown -h