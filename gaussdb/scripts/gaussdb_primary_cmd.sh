#!/bin/bash
ROOTPATH=$(cd "$(dirname "$0")"; pwd)
cd $ROOTPATH/../../
result=$(python install.py -U gaussdba:dbgrp -R $gs_app_path -D $gs_data_path -P "-E UTF8" -P "--pwpasswd=$dbUserGaussdbaPassword" -P "--locale=zh_CN.UTF-8" -C port=$database_port)
exit $?
