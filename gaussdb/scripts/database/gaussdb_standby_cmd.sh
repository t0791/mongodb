#!/bin/bash
ROOTPATH=$(cd "$(dirname "$0")"; pwd)
cd $ROOTPATH/../../
result=$(python install.py -U gaussdba:dbgrp -R $gs_app_path -D $gs_data_path -P "-E UTF8" -P "--pwpasswd=$dbUserGaussdbaPassword" -P "--locale=zh_CN.UTF-8" -C port=$database_port -C "replconninfo1='localhost=$sync_localhost_ip1 localport=$sync_localhost_port1 remotehost=$sync_remotehost_ip1 remoteport=$sync_remotehost_port1,localhost=$sync_localhost_ip2 localport=$sync_localhost_port2 remotehost=$sync_remotehost_ip2 remoteport=$sync_remotehost_port2'")
exit $?
