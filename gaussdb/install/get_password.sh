#!/bin/bash
# Copyright (c) Huawei Technologies Co., Ltd. 2014- . All rights reserved.  
# Author:  
#
# Description :decrypt the passwd message
#

##------------- configure start -----------##
AMUSER="topus"
JDK_VERSION=jdk
JAVA_PATH=/opt/$AMUSER/$JDK_VERSION/bin

RESULT_OK=0
RESULT_ERROR=1
PARAMETER_ERROR=2

#The path of tool jar
CRYPTO_JAR_PATH=$(cd "$(dirname "$0")"; pwd)

#The name of jar && the sourch message which need crypto $$ the final message after crypto 
sourcemsg=""

#Check the path is existed or not
if [ ! -d $CRYPTO_JAR_PATH ];then
    echo -e "The tool jar'path $CRYPTO_JAR_PATH is not exist." 
    exit $PARAMETER_ERROR
fi

sourcemsg=`grep "$2" $CRYPTO_JAR_PATH/cipher-text.properties | awk -F= '{print $2}'`
if [ $? -ne 0 ];then
    echo $sourcemsg
    exit $RESULT_ERROR
fi
echo $sourcemsg
exit $RESULT_OK
