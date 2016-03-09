#!/bin/bash
CRYPTO_JAR_PATH=$(cd "$(dirname "$0")"; pwd)

echo $keyValue=[$key] >> $CRYPTO_JAR_PATH/cipherPwd.ini
exit $?
