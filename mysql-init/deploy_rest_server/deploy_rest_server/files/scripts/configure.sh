#!/bin/bash
set -e

sudo echo "umask 027" >> ~/.profile
source ~/.profile

TEMP_DIR="/var/paas/jobs"
deploy_rest_server_ROOT=${TEMP_DIR}/deploy_rest_server

cd ${deploy_rest_server_ROOT}
#if [ $deploy_os == 'EulerOS' ]; then
#  sudo rpm -ivh --force ${deploy_rest_server_ROOT}/oracle/libaio-0.3.110-alt1.x86_64.rpm
#  sudo rpm -ivh --force ${deploy_rest_server_ROOT}/oracle/libaio-devel-0.3.110-alt1.x86_64.rpm
#fi

mysqlsource="$mysql_deploymgrdb_user:$mysql_deploymgrdb_password@tcp(${mysql_ip}:$mysql_port)/$mysql_deploymgrdb_name?charset=utf8&loc=Asia%2FShanghai&timeout=30s&readTimeout=5s&writeTimeout=5s"
datasource_encrypt=`/var/paas/crypto_tool -text $mysqlsource`
if [ $? -ne 0 ];then
        exit 1
fi
cf_admin_account_password_encrypt=`/var/paas/crypto_tool -text $cf_admin_account_password`
if [ $? -ne 0 ];then
        exit 1
fi

# update config.
CONF_PATH=${deploy_rest_server_ROOT}/conf/app.conf
#for Policy syn
sed -i "s|{dbsourceURL}|$datasource_encrypt|g" ${CONF_PATH}
sed -i "s|{cf_admin_account_password}|$cf_admin_account_password_encrypt|g" ${CONF_PATH}
sed -i "s|{ObjectClass}|$ObjectClass|g" ${deploy_rest_server_ROOT}/conf/policytemplate.json

NIC=${2:-eth0}
LOCAL_IP=$(ifconfig $NIC | awk '/inet /{ print $2 }' | tr -d "addr:")

#hostname
hostname=`cat /etc/hostname`

is_exist=`grep "${LOCAL_IP}" /etc/hosts | grep ${hostname} | wc -l`
if [ $is_exist -lt 1 ]; then
    is_ip_exist=`grep "${LOCAL_IP}" /etc/hosts | wc -l`
    echo $is_ip_exist
    if [ $is_ip_exist -lt 1 ]; then
        sudo su -c "echo '${LOCAL_IP} ${hostname}' >> /etc/hosts"
    else
        grep "${LOCAL_IP}" -n /etc/hosts > hosttmp.txt
        sed -i "s/:/  /" hosttmp.txt
        line_num=`awk '{print $1;exit}' hosttmp.txt`
        rm -f hosttmp.txt
        sudo sed -i "$line_num{/$LOCAL_IP/{s/$/& `hostname`/}}" /etc/hosts                                                                                                             
    fi
fi

sudo chmod g-w,o-rwx -R ${deploy_rest_server_ROOT}
