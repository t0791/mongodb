#!/bin/bash
# Copyright (c) Huawei Technologies Co., Ltd. 2014- . All rights reserved.  
# Author:  
#
# Description :decrypt the passwd message
#

##------------- configure start -----------##
AMUSER="gaussdb"
JDK_VERSION=jdk
JAVA_PATH=/opt/$AMUSER/$JDK_VERSION/bin

RESULT_OK=0
RESULT_ERROR=1
PARAMETER_ERROR=2

#The path of tool jar
CRYPTO_JAR_PATH=$(cd "$(dirname "$0")"; pwd)
CIPHER_ORG_PATH=$CRYPTO_JAR_PATH/../gaussmgt/repository/conf/security

#The name of jar && the sourch message which need crypto $$ the final message after crypto 
crypto_jar=""
sourcemsg=""

#Get the jar's name
crypto_jar=$(ls $CRYPTO_JAR_PATH|grep com.huawei.am.igt.pwdjobexecutor-1.0.0.jar 2>/dev/null)
if [ $? -ne 0 ];then
    echo -e "Can not find the tool jar which is used to encrypt and decrypt." 
    exit $PARAMETER_ERROR
fi

rm $CRYPTO_JAR_PATH/cipherPwd.ini >> /dev/null 2>&1
touch $CRYPTO_JAR_PATH/cipherPwd.ini
while read line
do
    key=`echo $line | awk -F = '{ print $1;}'`
    if [ "$key" != "" ]; then
        sourcemsg=`grep "$key" $CRYPTO_JAR_PATH/cipher-text.properties | awk -F= '{print $2}'`
		
		echo "#!/bin/bash" > $CRYPTO_JAR_PATH/temp.sh
		chmod +x $CRYPTO_JAR_PATH/temp.sh
		echo "export keyValue=$key" >> $CRYPTO_JAR_PATH/temp.sh
		result=`$JAVA_PATH/java -jar $crypto_jar "key=$sourcemsg" $CRYPTO_JAR_PATH/gen_cipher_decry.sh $CRYPTO_JAR_PATH/crypto 2>> /dev/null`
        if [ $? -ne 0 ];then
            exit $RESULT_ERROR
        fi
    fi
done <  $CIPHER_ORG_PATH/cipher-text.properties

echo >> $CRYPTO_JAR_PATH/cipherPwd.ini
mv $CRYPTO_JAR_PATH/cipherPwd.ini $CIPHER_ORG_PATH/cipher-text.properties
exit $RESULT_OK