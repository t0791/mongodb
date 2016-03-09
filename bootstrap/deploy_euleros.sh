#!/bin/bash

# //////////////////////////////////////////////////////////////////////////// #
#                                                                              #
#  description : install, uninstall                                            #
#  create Date : 2014/10/14                                                    #
#  Author      : w00241627                                                     #
#  Since       : Foundation PaaS  V100R001C00                                  #
#                                                                              #
#  Copyright (c) Huawei Technologies Co., Ltd. 2013-2014. All rights reserved. #
#                                                                              #
# //////////////////////////////////////////////////////////////////////////// #

# //////////////////////////////////////////////////////////////////////////// #
#                                                                              #
#                              Global Variables                                #
#                                                                              #
# //////////////////////////////////////////////////////////////////////////// #

USERID=`id -u`

UTILITY="$0"
UTILITY_NAME=${UTILITY##*/}
USERNAME=`whoami`


RESULT_OK=0
RESULT_ERROR=1
PARAMETER_ERROR=2
USER_REJECTED=3
BUILD_ERROR=6

DATE=$(date +%Y%m%d)
ROOTPATH=$(cd "$(dirname "$0")"; pwd)

LOG_FILE_PATH="$ROOTPATH/../systemlog/$DATE"
LOG_FILE="$LOG_FILE_PATH/uninstall_temp.log"
HOST_IP=`LANG=C ifconfig eth0 | awk '/inet /{ print $2 }'`
# The default system log for shell 

# //////////////////////////////////////////////////////////////////////////// #
#                                                                              #
#                               Display Function                               #
#                                                                              #
# //////////////////////////////////////////////////////////////////////////// #

# status flags for display
FTAG="\033[31;49;1mFAILURE\033[0m"
STAG="\033[32;49;1mSUCCESS\033[0m"
RTAG="\033[33;49;1mRunning\033[0m"

sTAG="\033[36;49msuccess\033[0m"
fTAG="\033[35;49mfailure\033[0m"

# **************************************************************************** #
# Function    : print_help
# Description : show the help message of this script
# Parameter   : none
# Return      : none
# Since       : Foundation PaaS V100R001C00
# Others      :
# **************************************************************************** #
function print_help()
{
echo -e "
    $UTILITY_NAME is a UTILITY to install/uninstall and start/stop topus server.
    
Usage:
    $UTILITY_NAME install   [-v]
    $UTILITY_NAME uninstall [-v]
    $UTILITY_NAME start     [-v] [-m primary/standby]
    $UTILITY_NAME stop      [-v]
    $UTILITY_NAME status

Common options:
    -m, --mode             start mode
    -v, --verbose          more verbose marginal on marginal errors.
    -V, --version          output version information, then exit.
    -?, --help             show this help info, then exit.
"
}

# **************************************************************************** #
# Function    : print_verbose
# Description : show the information if verbose is set
# Parameter   : $1 -- information
# Return      : none
# Since       : Foundation PaaS V100R001C00
# Others      :
# **************************************************************************** #

function print_verbose()
{
    information="$1"
    if [ -n "$information" ] && [ "$verbose" = "-v" ]; then
        echo -e "$information"
    fi
}

# **************************************************************************** #
# Function    : print_progress
# Description : print progress
# Parameter   : $1 - current step index
#               $2 - total step num
# Return      : none
# Since       : Foundation PaaS V100R001C00
# Others      : w00241627
# **************************************************************************** #

function print_progress()
{
    len=${#1}
    if [ $len -eq 1 ]; then
        echo -e "[\033[33;49;1m step  $1 of $2 \033[0m] $3 ..."
    else
        echo -e "[\033[33;49;1m step $1 of $2 \033[0m] $3 ..."
    fi
}

# **************************************************************************** #
# Function    : print_log_to_screen
# Description : print_log_to_screen
# Parameter   : $1 - detail process you want to display
#               $2 - status flag (can be empty)
# Return      : none
# Since       : Foundation PaaS V100R001C00
# Others      : w00241627
# **************************************************************************** #

function print_log_to_screen()
{
    if [ "$2" = "" ]; then
        black_str="                                                               \c"
        str_len=${#1}
        echo -e "+ $1${black_str:$str_len}"    
    else
        black_str="                                                               $2"
        str_len=${#1}
        echo -e "+ $1${black_str:$str_len}"
    fi
}

# **************************************************************************** #
# Function    : central_print
# Description : print a string centrally in giving length
# Parameter   : $1 - string length
#               $2 - string length
# Return      : none
# Since       : Foundation PaaS V100R001C00
# Others      : w00241627
# **************************************************************************** #

function central_print()
{
    local black_str="                                                                        "
    
    local str_len=${#2}
    local tmp_len=`expr $1 - $str_len`
    local pre_len=`expr $tmp_len / 2`
    local sub_len=`expr $str_len + $pre_len`
    
    black_str=${black_str:0:$1}
    
    echo -e "${black_str:0:$pre_len}$2${black_str:$sub_len}\c"
}
function print_ip()
{
    echo -e "|\c"
    central_print 20 "$1"
    echo -e "|\c"
    central_print 20 "$2" 
    echo -e "|"
}
# **************************************************************************** #
# Function    : print_title
# Description : print_title
# Parameter   : $1 - title string you want to display
# Return      : none
# Since       : Foundation PaaS V100R001C00
# Others      : w00241627
# **************************************************************************** #

function print_title()
{
    central_str=`central_print 70 "$1"`
    echo -e "
------------------------------------------------------------------------
|$central_str|
------------------------------------------------------------------------
"
}

# **************************************************************************** #
# Function    : check_port
# Description : check_port
# Parameter   : $1 - appname
#               $2 - port
#               $3 - retrying in TIMER seconds
#               $4 - HOST
# Return      : none
# Since       : Foundation PaaS V100R001C00
# Others      : 
# **************************************************************************** #

function check_port
{
    APP=$1
    PORT=$2
    TIMER=$3
    HOST=$4

    for i in {1..24}
    do
        echo -ne "checking whether ${APP} port ${PORT} is opened on ${HOST:-localhost}..." >> $LOG_FILE_PATH/install_temp.log
        netstat -anp|grep ${PORT}
        if [ $? -eq 0 ]; then
            echo "${APP} port ${PORT} is opened" >> $LOG_FILE_PATH/install_temp.log
            return
        else
            echo "WARNING: ${APP} port ${PORT} is closed, retrying in ${TIMER:-5} seconds ($i)" >> $LOG_FILE_PATH/install_temp.log
            sleep ${TIMER:-5}
        fi
    done
    echo  "${APP} port ${PORT} is closed!" >> $LOG_FILE_PATH/install_temp.log
}

function install_salt()
{
    salt_root=/var/paas/packages/package/$version/salt
    cd $salt_root
    tar -zvxf salt.tar.gz >> /dev/null 2>&1
    
    cd salt-install
    sudo bash install.sh master >> $LOG_FILE_PATH/install_temp.log 2>&1
    cd -
    sudo rm -rf salt-install
    sleep 5
    sudo service salt-master stop
    pkill salt-master

    sudo chown -R paas:paas /etc/salt
    if [ ! -d /var/paas/sys/cache/salt ];then
        mkdir -p /var/paas/sys/cache/salt
    fi
    if [ ! -d /var/paas/sys/log/salt ];then
        mkdir -p /var/paas/sys/log/salt
    fi
    if [ ! -d /var/paas/sys/run/salt ];then
        mkdir -p /var/paas/sys/run/salt
    fi
    sudo chown -R paas:paas /var/paas/sys
    chmod -R 750 /var/paas/sys

    mkdir /etc/salt/master.d
    touch /etc/salt/master.d/master.conf	
    cat > /etc/salt/master.d/master.conf << EOF
file_roots:
  paas-iam:
    - /var/paas/paas-iam/saltstack/salt/states
    - /var/paas/paas-iam/release
    - /var/paas
    - /home/paas
  paas-iam-dev:
    - /var/paas/paas-iam/saltstack/salt/states
  cloudify:
    - /var/paas/cloudify/saltstack/salt/states
    - /var/paas/cloudify/release
    - /etc
    - /var/paas
    - /home/paas
  cloudify-dev:
    - /var/paas/cloudify/saltstack/salt/
    - /var/paas/cloudify/saltstack/salt/states/paas-common
  cde:
    - /var/paas/cde/saltstack/salt/states
    - /var/paas/cde/release
    - /etc
    - /var/paas
    - /home/paas
  cde-dev:
    - /var/paas/cde/saltstack/salt/states
    - /var/paas/cde/saltstack/salt/states/paas-common
  cce:
    - /var/paas/cce/saltstack/salt/states
    - /var/paas/cce/release
    - /etc
    - /var/paas
    - /home/paas
  cce-dev:
    - /var/paas/cce/saltstack/salt/states
    - /var/paas/cce/saltstack/salt/states/paas-common
  cae:
    - /var/paas/cae/saltstack/salt/states
    - /var/paas/cae/release
    - /etc
    - /var/paas
    - /home/paas
  cae-dev:
    - /var/paas/cae/saltstack/salt/states
    - /var/paas/cae/saltstack/salt/states/paas-common
  common:
    - /var/paas/common/saltstack/salt/states
    - /var/paas/common/release
    - /var/paas
    - /home/paas
  common-dev:
    - /var/paas/common/saltstack/salt/states
    - /var/paas/common/saltstack/salt/states/paas-common
  servicemgr:
    - /var/paas/servicemgr/saltstack/salt/states
    - /var/paas/servicemgr/release
    - /var/paas
    - /home/paas
  servicemgr-dev:
    - /var/paas/servicemgr/saltstack/salt/states
  ops-salt:
    - /var/paas/ops/saltstack/salt/states
    - /var/paas/ops/release
    - /var/paas
    - /home/paas
    - /etc
  ops-dev:
    - /var/paas/ops/saltstack/salt/states/
    - /var/paas/ops/saltstack/salt/states/paas-common
  om-salt:
    - /var/paas/om/saltstack/salt/states
    - /var/paas/om/release
    - /var/paas
    - /home/paas
    - /etc
  om-dev:
    - /var/paas/om/saltstack/salt/states/
    - /var/paas/om/saltstack/salt/states/paas-common
  docker-hub:
    - /var/paas/docker-hub/saltstack/salt/states
    - /var/paas/docker-hub/release
    - /var/paas
    - /home/paas
    - /etc
  docker-hub-dev:
    - /var/paas/docker-hub/saltstack/salt/states/
    - /var/paas/docker-hub/saltstack/salt/states/paas-common
pillar_roots:
  paas-iam:
    - /var/paas/paas-iam/saltstack/salt/pillar
  paas-iam-dev:
    - /var/paas/paas-iam/saltstack/salt/pillar
  cloudify:
    - /var/paas/cloudify/saltstack/salt/pillar
  cloudify-dev:
    - /var/paas/cloudify/saltstack/salt/pillar
  cde:
    - /var/paas/cde/saltstack/salt/pillar
  cde-dev:
    - /var/paas/cde/saltstack/salt/pillar
  cce:
    - /var/paas/cce/saltstack/salt/pillar
  cce-dev:
    - /var/paas/cce/saltstack/salt/pillar
  common:
    - /var/paas/common/saltstack/salt/pillar
  common-dev:
    - /var/paas/common/saltstack/salt/pillar
  cae:
    - /var/paas/cae/saltstack/salt/pillar
  cae-dev:
    - /var/paas/cae/saltstack/salt/pillar
  servicemgr:
    - /var/paas/servicemgr/saltstack/salt/pillar
  servicemgr-dev:
    - /var/paas/servicemgr/saltstack/salt/pillar
  ops-salt:
    - /var/paas/ops/saltstack/salt/pillar
  ops-dev:
    - /var/paas/ops/saltstack/salt/pillar
  om-salt:
    - /var/paas/om/saltstack/salt/pillar
  om-dev:
    - /var/paas/om/saltstack/salt/pillar
  docker-hub:
    - /var/paas/docker-hub/saltstack/salt/pillar
  docker-hub-dev:
    - /var/paas/docker-hub/saltstack/salt/pillar
state_events: True
user: paas
failhard: True
auto_accept: True
worker_threads: 20
publish_port: 5001
ret_port: 5002
log_file: /var/paas/sys/log/salt/master
key_logfile: /var/paas/sys/log/salt/key
log_level: warning
log_level_logfile: warning
timeout: 20
gather_job_timeout: 20
pidfile: /var/paas/sys/run/salt/master.pid
sock_dir: /var/paas/sys/run/salt/master
cachedir: /var/paas/sys/cache/salt/master
EOF
    if [ -f /etc/logrotate.d/salt ]; then
        sudo sed -i "s|\/var\/log\/salt|\/var\/paas\/sys\/log\/salt|g" /etc/logrotate.d/salt
    fi

    sudo service salt-master start
    chmod g-wx,o-rwx -R /var/paas/sys/cache/salt
    chmod g-wx,o-rwx -R /var/paas/sys/run/salt
    chmod 640 /var/paas/sys/log/salt/*
    sudo rm -rf /var/log/salt
    sudo rm -rf /var/run/salt
    sudo rm -rf /var/cache/salt

    return $RESULT_OK
}
 
function uninstall_salt()
{
    n=$(rpm -qa | grep salt | wc -l) >> /dev/null 2>&1
    if [ $n -eq 0 ];then
        exit 1
    fi
    
    sudo service salt-master stop
    pkill salt-master

    salt_root=/var/paas/packages/package/$version/salt
    cd $salt_root
    tar -zvxf salt.tar.gz >> /dev/null 2>&1

    #uninstall master
    sudo rpm -qa | grep salt | xargs sudo rpm -e #>> /dev/null 2>&1

    #uninstall dependence pack
    LINE=`cat salt-install/dependecelist | wc -l`
    while [ $LINE -ge 1 ]
    do
        name=`sed -n ${LINE}p salt-install/dependecelist`
	n=$(rpm -qa  | grep ${name%\.*} | wc -l) >> /dev/null 2>&1 
        if [ $n -ne 0 ]; then
            sudo rpm -e ${name%\.*} >> /dev/null 2>&1
        fi
        LINE=$((LINE - 1))
    done
    
    sudo rm -rf salt-install
    rm -rf /etc/salt/*
    rm -rf /var/paas/sys/cache/salt
    rm -rf /var/paas/sys/run/salt
    rm -rf /var/paas/sys/log/salt


    return $RESULT_OK
}

function install_expect()
{
    rpm -qa | grep expect >> /dev/null 2>&1
    if [ $? -ne 0 ]; then
        cp /var/paas/packages/package/$version/common/expect.tar.gz $ROOTPATH/
        cd $ROOTPATH/
        tar zxvf expect.tar.gz >> /dev/null 2>&1
        
        rpm -qa | grep tcl >> /dev/null 2>&1
        if [ $? -ne 0 ]; then
             echo install ....
             result=$(sudo rpm -i --force tcl-8.5.13-4.el7.x86_64.rpm)
             if [ $? -ne 0 ]; then
                print_log_to_screen "install tcl $line" "$fTAG: $result"
                return $RESULT_ERROR
             fi
        fi
        result=$(sudo rpm -i expect-5.45-12.el7.x86_64.rpm)
        if [ $? -ne 0 ]; then
            print_log_to_screen "install expect  $line" "$fTAG: $result"
            return $RESULT_ERROR
        fi
        rm -rf  $ROOTPATH/expect-5.45-12.el7.x86_64.rpm
        rm -rf  $ROOTPATH/tcl-8.5.13-4.el7.x86_64.rpm
        rm -rf  $ROOTPATH/expect.tar.gz
    fi
}

# **************************************************************************** #
# Function    : create_http_service
# Description : create_http_service
# Parameter   : $1 - title string you want to display
# Return      : none
# Since       : Foundation PaaS V100R001C00
# Others      : w00241627
# **************************************************************************** #

function install()
{

    if [ ! -f $ROOTPATH/monit_done ]; then
        if [ "$mode" = "" ] || [ "$mode" = "monit" ]; then
            install_monit >>$LOG_FILE_PATH/install_temp.log 2>&1
            if [ $? -ne 0 ] ; then
                print_log_to_screen "install monit" "$fTAG"
                return $RESULT_ERROR
            fi
            print_log_to_screen "install monit" "$sTAG"
            touch $ROOTPATH/monit_done
        fi
        
    fi
    if [ ! -f $ROOTPATH/manager_done ]; then
        if [ "$mode" = "" ] || [ "$mode" = "manager" ]; then
            install_manager >>$LOG_FILE_PATH/install_temp.log 2>&1
            if [ $? -ne 0 ] ; then
                print_log_to_screen "install manager" "$fTAG"
                return $RESULT_ERROR
            fi
            print_log_to_screen "install manager" "$sTAG"
            touch $ROOTPATH/manager_done
        fi
        
    fi
    if [ ! -f $ROOTPATH/mysql_done ]; then
        if [ "$mode" = "" ] || [ "$mode" = "mysql" ]; then
            install_mysql >>$LOG_FILE_PATH/install_temp.log 2>&1
            if [ $? -ne 0 ] ; then
                print_log_to_screen "install mysql" "$fTAG"
                return $RESULT_ERROR
            fi
            print_log_to_screen "install mysql" "$sTAG"
            touch $ROOTPATH/mysql_done
        fi
    fi
    if [ ! -f $ROOTPATH/etcd_done ]; then
        if [ "$mode" = "" ] || [ "$mode" = "etcd" ]; then
            install_etcd >>$LOG_FILE_PATH/install_temp.log 2>&1
            if [ $? -ne 0 ] ; then
                print_log_to_screen "install etcd" "$fTAG"
                #return $RESULT_ERROR
            fi
            print_log_to_screen "install etcd" "$sTAG"
            touch $ROOTPATH/etcd_done
        fi
    fi
    if [ ! -f $ROOTPATH/skydns_done ]; then
        if [ "$mode" = "" ] || [ "$mode" = "skydns" ]; then
            install_skydns >>$LOG_FILE_PATH/install_temp.log 2>&1
            if [ $? -ne 0 ] ; then
                print_log_to_screen "install skydns" "$fTAG"
                return $RESULT_ERROR
            fi
            print_log_to_screen "install skydns" "$sTAG"
            touch $ROOTPATH/skydns_done
        fi
    fi
    if [ ! -f $ROOTPATH/deploy_rest_server_done ]; then
        if [ "$mode" = "" ] || [ "$mode" = "deploy_rest_server" ]; then
            install_deploy_rest_server >>$LOG_FILE_PATH/install_temp.log 2>&1
            if [ $? -ne 0 ] ; then
                print_log_to_screen "install deploy_rest_server" "$fTAG"
                return $RESULT_ERROR
            fi
            print_log_to_screen "install deploy_rest_server" "$sTAG"
            touch $ROOTPATH/deploy_rest_server_done
        fi
    fi
    
    if [ ! -f $ROOTPATH/salt_done ]; then
        if [ "$mode" = "" ] || [ "$mode" = "salt" ]; then
            install_salt >> $LOG_FILE_PATH/install_temp.log 2>&1
            if [ $? -ne 0 ] ; then
                print_log_to_screen "install salt" "$fTAG"
                return $RESULT_ERROR
            fi
            print_log_to_screen "install salt" "$sTAG"
            touch $ROOTPATH/salt_done
        fi
    fi
    
    install_expect >> /dev/null 2>&1
    
    conf_logrotate >> /dev/null 2>&1
    modify_permission >> /dev/null 2>&1
    sudo service firewalld start
    sudo firewall-cmd --zone=public --add-port=8031/tcp  --add-port=7777/tcp --add-port=5001/tcp --add-port=5002/tcp --add-port=5306/tcp --permanent
    sudo firewall-cmd --reload

    return $RESULT_OK
}

function modify_permission()
{
    sudo chmod g-wx,o-rwx -R /var/paas/cloudify/
    sudo chmod g-wx,o-rwx -R /var/paas/deploy_rest_server/
    sudo chmod g-wx,o-rwx -R /var/paas/scripts 
    sudo chmod g-wx,o-rwx -R /var/paas/sys/
    sudo chmod g-wx,o-rwx -R /var/paas/components/
    sudo chmod g-wx,o-rwx -R $ROOTPATH/../
    chmod g-wx,o-rwx -R /home/paas/bootstrap
    chmod g-wx,o-rwx -R /var/paas/bootstrap
    sudo chmod g-rwx,o-rwx /etc/ssh/sshd_config
}

function conf_logrotate()
{
    #add log rotate crontab job
    BOOTSTRAP_ROOT=/var/paas/bootstrap
    mkdir -p -m 750 $BOOTSTRAP_ROOT/logrotate
    touch $BOOTSTRAP_ROOT/logrotate/logrotate.conf
    chmod 640 $BOOTSTRAP_ROOT/logrotate/logrotate.conf
    cat > $BOOTSTRAP_ROOT/logrotate/logrotate.conf <<EOF
        /var/paas/*.log
        /var/paas/monit/*.log
        /var/paas/sys/log/mysql/*.log
        /var/paas/sys/log/*.log
        /var/paas/sys/log/deploy_rest_server/*.log
        /var/paas/deploy_rest_server/*.log
        /var/paas/deploy_rest_server/policybootstrap/*.log
        /var/paas/sys/log/nginx/*.log
        /var/paas/sys/log/cloudify/*.log
        /var/paas/sys/log/monit/*.log
        /var/paas/sys/log/skydns/*.log
        {
            missingok
            rotate 20
            compress
            copytruncate
            notifempty
            size 50M
        }
EOF
    touch $BOOTSTRAP_ROOT/logrotate/crontab.conf
    chmod 640 $BOOTSTRAP_ROOT/logrotate/crontab.conf
    sudo crontab -u root -l > $BOOTSTRAP_ROOT/logrotate/crontab.conf
    if [ `cat $BOOTSTRAP_ROOT/logrotate/crontab.conf|grep -c "$BOOTSTRAP_ROOT/logrotate/logrotate.conf"` == 0 ];then
    cat >> $BOOTSTRAP_ROOT/logrotate/crontab.conf <<EOF
    45 * * * * su paas -c "/usr/sbin/logrotate $BOOTSTRAP_ROOT/logrotate/logrotate.conf 2>/dev/null"
EOF
    fi
    #start logrotate crontab job
    sudo crontab -u root $BOOTSTRAP_ROOT/logrotate/crontab.conf
}

#install monit
function config_runsv(){
    sudo touch /etc/systemd/system/runsvdir.service
    sudo chown paas:paas /etc/systemd/system/runsvdir.service
    sudo cat > /etc/systemd/system/runsvdir.service <<EOF
[Unit]
Description=runsv
[Service]
Type=simple
ExecStart=/usr/sbin/runsvdir -P /etc/service
[Install]
WantedBy=multi-user.target
EOF
}

function start_runsv(){
    config_runsv
    sudo systemctl daemon-reload
    sudo systemctl restart runsvdir.service
    sudo systemctl enable runsvdir.service
}

function install_monit()
{
    rm -rf /var/paas/monit/opsmgr-plugin
    rm -rf /var/paas/monit/opsmgr-plugin.zip
    
    mkdir -p /var/paas/monit
    cp /var/paas/packages/spec/ops_mgr/opsmgr-plugin/opsmgr-plugin.zip /var/paas/monit
    cd /var/paas/monit 
    unzip opsmgr-plugin.zip
    
    cd /var/paas/monit/opsmgr-plugin/monit/install
    #install dependence
    tar zxf monit_runit_agent.tar.gz
    cd /var/paas/monit/opsmgr-plugin/monit/install/monit_runit_agent/runit
    rpm -qa | grep runit >> $LOG_FILE_PATH/install_temp.log 2>&1
    if [ $? -ne 0 ]; then
        sudo rpm -i runit-2.1.1-7.el7.centos.x86_64.rpm
    fi
    sudo mkdir -p /etc/sv/monit
    #cp_config
    sudo cp /var/paas/monit/opsmgr-plugin/monit/install/monit/run /etc/sv/monit/run
    sudo chmod +x /etc/sv/monit/run
    #install monit
    cd /var/paas/monit/opsmgr-plugin/monit/install/monit_runit_agent/monit
    mkdir -p /var/paas/monit/bin
    cp monit /var/paas/monit/bin
    mkdir -p /var/paas/monit/etc
    sudo chmod -R 750 /var/paas/monit
    cp monitrc /var/paas/monit/etc
    sudo chmod 0700 /var/paas/monit/etc/monitrc
    #start_runsv
    start_runsv
    sudo ln -s /etc/sv/monit/ /etc/service/monit
    rm -rf /var/paas/monit/opsmgr-plugin
    rm -rf /var/paas/monit/opsmgr-plugin.zip
    # fetch monit-related files.
    utils_path="/var/paas/scripts/utils"
    if [ ! -d ${utils_path} ]; then
        mkdir -p ${utils_path}
        cp $ROOTPATH/monitfile/utils/* ${utils_path}
        chmod -R 750 ${utils_path}
        chmod 700 ${utils_path}/*
    fi
    echo $PATH | grep "/var/paas/monit/bin"
    if [ $? -ne 0 ]; then
       echo "export PATH=/var/paas/monit/bin:\$PATH" >> /home/paas/.bashrc
       source /home/paas/.bashrc        
    fi
    cd $ROOTPATH
}
function install_deploy_rest_server()
{
    if [ -f $ROOTPATH/deploy_rest_server/config/deploy_rest_server.env ]; then
        source $ROOTPATH/deploy_rest_server/config/deploy_rest_server.env
    fi
    mysql_root=/var/paas/mysql
    mkdir -p /var/paas/sys/log
    deploy_rest_server_root=/var/paas/deploy_rest_server
    if [ ! -d "$deploy_rest_server_root" ]; then
        mkdir -p $deploy_rest_server_root
    fi

    # fetch monit-related files.
    utils_path="/var/paas/scripts/utils"
    if [ ! -d ${utils_path} ]; then
        mkdir -p ${utils_path}
        cp $ROOTPATH/monitfile/utils/* ${utils_path}
        chmod 750 -R ${utils_path}
        chmod 700 ${utils_path}/*
    fi
    deploy_rest_server_ctl_path="/var/paas/jobs/deploy_rest_server/bin"
    mkdir -p ${deploy_rest_server_ctl_path}
    cp $ROOTPATH/monitfile/deploy_rest_server/deploy_rest_server_ctl ${deploy_rest_server_ctl_path}
    chmod 750 -R /var/paas/jobs/deploy_rest_server
    chmod 700 ${deploy_rest_server_ctl_path}/*
    deploy_rest_server_monitrc_path="/var/paas/monit/job"
    if [ ! -d ${deploy_rest_server_monitrc_path} ]; then
        mkdir -p ${deploy_rest_server_monitrc_path}
        chmod 750 -R ${deploy_rest_server_monitrc_path}
    fi
    cp $ROOTPATH/monitfile/deploy_rest_server/deploy_rest_server.monitrc ${deploy_rest_server_monitrc_path}
    chmod 640 ${deploy_rest_server_monitrc_path}/*
    
    deploy_rest_server_monitrc=${deploy_rest_server_monitrc_path}/deploy_rest_server.monitrc
    mkdir -p ${deploy_rest_server_root}/conf/
    cp /var/paas/packages/package/$version/deploy_mgr/deploy-rest-server.tgz $deploy_rest_server_root
    cd $deploy_rest_server_root
    tar -zxf deploy-rest-server.tgz
    export LD_LIBRARY_PATH=${deploy_rest_server_root}/oracle/instantclient_12_1:$LD_LIBRARY_PATH
    cp $ROOTPATH/deploy_rest_server/config/app.conf ${deploy_rest_server_root}/conf/
    cd $deploy_rest_server_root
    #sudo dpkg -i ${deploy_rest_server_root}/oracle/*.deb
    sudo rpm -i ${deploy_rest_server_root}/oracle/*.rpm
    ip=$(echo "$httpservice" | awk -F ':' '{print $1}')
    CONF_PATH=${deploy_rest_server_root}/conf/app.conf
    mysqlsource="$mysql_deploymgrdb_user:$mysql_deploymgrdb_password@tcp($ip:$mysql_port)/dmdb?charset=utf8"
    datasource_encrypt=`/var/paas/crypto_tool -text $mysqlsource`
    if [ $? -ne 0 ];then
        exit 1
    fi
    cf_admin_account_password_encrypt=`/var/paas/crypto_tool -text $cf_admin_account_password`
    if [ $? -ne 0 ];then
        exit 1
    fi
    sed -i "s|{httpport}|8031|g" ${CONF_PATH}
    sed -i "s|{httpaddr}|$HOST_IP|g" ${CONF_PATH}
    sed -i "s|{httpport}|8031|g" ${deploy_rest_server_monitrc}
    sed -i "s|{httpaddr}|$HOST_IP|g" ${deploy_rest_server_monitrc}
    sed -i "s|{datasource}|$datasource_encrypt|g" ${CONF_PATH}
    sed -i "s|{cfy_api_endpoint}|$ip:8100|g" ${CONF_PATH}
    sed -i "s|{policyengine_endpoint}|$paas_om_ops_endpoint|g" ${CONF_PATH}
    sed -i "s|{policyengine_template_path}|${deploy_rest_server_root}|g" ${CONF_PATH}
    sed -i "s|{cf_admin_account_password}|$cf_admin_account_password_encrypt|g" ${CONF_PATH}
    sed -i "s|{ObjectClass}|PaaS_Component|g" ${deploy_rest_server_root}/conf/policytemplate.json
    
    chmod g-wx,o-rwx -R /var/paas/deploy_rest_server/ 
    /var/paas/jobs/deploy_rest_server/bin/deploy_rest_server_ctl start
    sleep 1
    /var/paas/monit/bin/monit reload
    sleep 1

    #policy syn config set,when paas component deploy finish run this policybootstrap
    cd $deploy_rest_server_root
    mkdir -p ${deploy_rest_server_root}/policybootstrap
    mv  policybootstrap.tgz  ${deploy_rest_server_root}/policybootstrap  
    cd ${deploy_rest_server_root}/policybootstrap
    tar -zxf policybootstrap.tgz

    datasource="$mysql_deploymgrdb_user:$mysql_deploymgrdb_password@tcp($ip:$mysql_port)/dmdb?charset=utf8"
    datasource=`/var/paas/crypto_tool -text $datasource`
    CONF_PATH=${deploy_rest_server_root}/policybootstrap/conf/config.json
    sed -i "s|{policyEngineHost}|$paas_om_ops_endpoint|g" ${CONF_PATH}
    sed -i "s|{datasource}|$datasource|g" ${CONF_PATH}
    sed -i "s|{sqldriver}|mysql|g" ${CONF_PATH}
    sed -i "s|{templateConfigPath}|${deploy_rest_server_root}/policybootstrap/conf|g" ${CONF_PATH}
    sed -i "s|{ObjectClass}|PaaS_Component|g" ${deploy_rest_server_root}/policybootstrap/conf/policytemplate.json

    rm policybootstrap.tgz
    rm -rf $deploy_rest_server_root/deploy-rest-server.tgz
    return $RESULT_OK
}
function install_mysql()
{
    PACKAGE_DIR=/var/vcap/packages/mysql
    RUN_DIR=/var/vcap/sys/run/mysql
    LOG_DIR=/var/vcap/sys/log/mysql
    TMP_DIR=$PACKAGE_DIR/tmp
    DATA_DIR=/var/vcap/store/mysql
    LOG_BIN_DIR=/var/vcap/store/mysql-logs

    CHROOT_DIR=${mysql_chroot_dir}/mysql
    CHROOT_PACKAGE_DIR=${CHROOT_DIR}${PACKAGE_DIR}
    CHROOT_RUN_DIR=${CHROOT_DIR}${RUN_DIR}
    CHROOT_LOG_DIR=${CHROOT_DIR}${LOG_DIR}
    CHROOT_TMP_DIR=$CHROOT_PACKAGE_DIR/tmp
    CHROOT_DATA_DIR=${CHROOT_DIR}${DATA_DIR}
    CHROOT_LOG_BIN_DIR=${CHROOT_DIR}${LOG_BIN_DIR}
    
    # create dir
    if [ ! -d /var/vcap ]; then
    	sudo ln -s /var/paas /var/vcap
    fi
    
    mkdir -p ${PACKAGE_DIR} ${PACKAGE_DIR}/config
    mkdir -p ${TMP_DIR}
    
    cp /var/paas/packages/package/$version/common/mysql_dependency.tgz ${PACKAGE_DIR}
    cp /var/paas/packages/package/$version/common/mysql.tgz ${PACKAGE_DIR}

    pushd ${PACKAGE_DIR}
    tar -xzf mysql_dependency.tgz
    tar -xzf mysql.tgz 
    tar xzf mysql.tar.gz -C $PACKAGE_DIR
    rm mysql.tgz mysql.tar.gz mysql_dependency.tgz libaio1_0.3.109-4_amd64.deb
    mv audit_log.so $PACKAGE_DIR/lib/plugin
    popd

    cp $ROOTPATH/mysql/config/* ${PACKAGE_DIR}/config
    sed -i "s|{mysql_port}|$mysql_port|g" ${PACKAGE_DIR}/config/my-default.cnf
    sed -i "s|<%= mysql.chroot_dir %>|${mysql_chroot_dir}|g" ${PACKAGE_DIR}/config/my-default.cnf
    sudo sed -i "s|<%= bindaddress %>|$HOST_IP|g" ${PACKAGE_DIR}/config/my-default.cnf
    sudo sed -i "s/^user =.*/user=${mysql_user}/g" ${PACKAGE_DIR}/config/my-default.cnf
    sed -i 's|umask 007|umask 077 \nexport UMASK=0600 \nexport UMASK_DIR=0700|g' ${PACKAGE_DIR}/bin/mysqld_safe
    
    # interactive and wait timeout
    sed -i "s|<%= mysql_wait_timeout %>|$mysql_wait_timeout|g" ${PACKAGE_DIR}/config/my-default.cnf
    sed -i "s|<%= mysql_interactive_timeout %>|$mysql_interactive_timeout|g" ${PACKAGE_DIR}/config/my-default.cnf
    
    # Innodb log file
    sed -i "s|<%= innodb_log_file_size %>|$innodb_log_file_size|g" ${PACKAGE_DIR}/config/my-default.cnf
    sed -i "s|<%= expire_logs_days %>|$expire_logs_days|g" ${PACKAGE_DIR}/config/my-default.cnf
    
    # Audit_Log Configuration
    sed -i "s|<%= audit_log_policy %>|$audit_log_policy|g" ${PACKAGE_DIR}/config/my-default.cnf
    sed -i "s|<%= audit_log_format %>|$audit_log_format|g" ${PACKAGE_DIR}/config/my-default.cnf
    sed -i "s|<%= audit_log_file %>|$audit_log_file|g" ${PACKAGE_DIR}/config/my-default.cnf
    sed -i "s|<%= audit_log_rotate_on_size %>|$audit_log_rotate_on_size|g" ${PACKAGE_DIR}/config/my-default.cnf
    sed -i "s|<%= audit_log_rotations %>|$audit_log_rotations|g" ${PACKAGE_DIR}/config/my-default.cnf
    
    #update mysql_init
    sed -i "s|<%= mysql_max_queries_per_hour %>|$mysql_max_queries_per_hour|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_max_updates_per_hour %>|$mysql_max_updates_per_hour|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_max_connections_per_hour %>|$mysql_max_connections_per_hour|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_max_user_connections %>|$mysql_max_user_connections|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_admin_username %>|$mysql_admin_username|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_admin_password %>|$mysql_admin_password|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_deploymgrdb_user %>|$mysql_deploymgrdb_user|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_deploymgrdb_name %>|$mysql_deploymgrdb_name|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_deploymgrdb_password %>|$mysql_deploymgrdb_password|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_eventbusdb_user %>|$mysql_eventbusdb_user|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_eventbusdb_name %>|$mysql_eventbusdb_name|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_eventbusdb_password %>|$mysql_eventbusdb_password|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= mysql_ip %>|$HOST_IP|g" ${PACKAGE_DIR}/config/mysql_init
    sed -i "s|<%= om_ops_ip %>|$paas_om_ops_endpoint|g" ${PACKAGE_DIR}/config/mysql_init
    
    cp -f ${PACKAGE_DIR}/config/my-default.cnf ${PACKAGE_DIR}/support-files
    cp -f ${PACKAGE_DIR}/config/my-default.cnf ${PACKAGE_DIR}/my.cnf
    chmod 600 $PACKAGE_DIR/my.cnf
    
    sudo rm -rf /etc/my.cnf*
    mysql_ctl_path="/var/paas/jobs/mysql/bin"
    mkdir -p ${mysql_ctl_path}
    cp $ROOTPATH/monitfile/mysql/mysql_ctl ${mysql_ctl_path}
    chmod -R 750 ${mysql_ctl_path}
    chmod -R 750 ${mysql_ctl_path}/../
    
    if [ "${mysql_user}" != "paas" ]; then
    sudo useradd -r -g paas -m -s /usr/sbin/nologin ${mysql_user} -p $(echo "${mysql_user_passwd}" | openssl passwd -1 -stdin) 
	
    fi

    sudo sed -i "s/^mysql_user=.*/mysql_user=${mysql_user}/g" /var/paas/jobs/mysql/bin/mysql_ctl
    sudo sed -i "s|^CHROOT_DIR=.*|CHROOT_DIR=${mysql_chroot_dir}/mysql|g" /var/paas/jobs/mysql/bin/mysql_ctl
    	
    mysql_monitrc_path="/var/paas/monit/job"
    if [ ! -d ${mysql_monitrc_path} ]; then
        mkdir -p ${mysql_monitrc_path}
        chmod -R 750 ${mysql_monitrc_path}
    fi
    cp $ROOTPATH/monitfile/mysql/mysql.monitrc ${mysql_monitrc_path}
    sed -i "s|<%= mysql.chroot_dir %>|${mysql_chroot_dir}|g" ${mysql_monitrc_path}/mysql.monitrc
    
    chmod 640 ${mysql_monitrc_path}/*

    # setup chroot environment
    sudo mkdir -p $CHROOT_DIR
    sudo chown -R paas:paas ${mysql_chroot_dir}
    pushd ${CHROOT_DIR} > /dev/null
    mkdir -p etc
    mkdir -p $CHROOT_PACKAGE_DIR $CHROOT_RUN_DIR $CHROOT_LOG_DIR $CHROOT_DATA_DIR $CHROOT_TMP_DIR $CHROOT_LOG_BIN_DIR


    cp /etc/localtime etc
    echo "127.0.0.1 localhost" > etc/hosts

    grep "^${mysql_user}:" /etc/passwd > etc/passwd


    # for reading etc/passwd and etc/hosts
        mkdir -p lib64
        sudo cp `sudo find /lib64/ -name libnss_compat.so.2` lib64/
        sudo cp `sudo find /lib64/ -name libnss_files.so.2` lib64/
        sudo chown -R paas:paas lib64
    
    sudo mv $PACKAGE_DIR/* $CHROOT_PACKAGE_DIR
    popd > /dev/null
    rm -rf $PACKAGE_DIR

    ${CHROOT_PACKAGE_DIR}/scripts/mysql_install_db --user=${mysql_user} --tmpdir=${CHROOT_TMP_DIR} --basedir=${CHROOT_PACKAGE_DIR} --datadir=${CHROOT_DATA_DIR}

    chmod g-rwx,o-rwx -R ${CHROOT_DIR}/var/vcap/*
    sleep 2
    
    # sudo sed -i "s|/var/vcap/packages|/var/paas/mysql|g"  $CHROOT_PACKAGE_DIR/support-files/mysql.server
    # sed -i 's|\[mysqld\]|[mysqld]\nsecure_auth=1\nskip-symbolic-links=1\nlocal-infile = 0\nsafe-user-create = 1\n|g' $PACKAGE_DIR/my.cnf
   # update file permissions
   chmod -R o-rwx,g-rwx ${CHROOT_DATA_DIR}

   echo "export PATH=\$PATH:${CHROOT_PACKAGE_DIR}/bin" >> ~/.profile
   sudo chown -R ${mysql_user}:paas ${mysql_chroot_dir}
   sudo chmod 750 ${mysql_chroot_dir}
   sudo chmod 0750 ${CHROOT_DIR}/var/vcap/store
   sudo chmod 700 $CHROOT_DATA_DIR
   sudo chmod 700 $CHROOT_LOG_BIN_DIR
   sudo chmod -R 700 $CHROOT_PACKAGE_DIR
   sudo chmod 0750 ${CHROOT_DIR}
   sudo chmod 0750 ${CHROOT_DIR}/var
   sudo chmod 0750 ${CHROOT_DIR}/var/vcap
   sudo chmod 0750 ${CHROOT_DIR}/var/vcap/packages
   sudo chmod 0750 ${CHROOT_DIR}/var/vcap/packages/mysql
   sudo chmod -R 0750 ${CHROOT_DIR}/var/vcap/sys
      
    if [ "x$MYSQL_HISTFILE" == "x" ];then
      sudo sh -c " echo 'export MYSQL_HISTFILE=/dev/null'>>/etc/profile"
      sudo sh -c " source /etc/profile"
    fi

    bash /var/paas/jobs/mysql/bin/mysql_ctl start
    sleep 10
    /var/paas/monit/bin/monit reload

    APP="mysql"
    PORT=$mysql_port
    TIMER=10

    for i in {1..24}
    do
        echo -ne "checking whether ${APP} port ${PORT} is opened on ${HOST_IP:-localhost}..." >> $LOG_FILE_PATH/install_temp.log
        netstat -anp |grep ${PORT} >/dev/null
        if [ $? -eq 0 ]; then
            echo "${APP} port ${PORT} is opened" >> $LOG_FILE_PATH/install_temp.log
            break
        else
            echo "WARNING: ${APP} port ${PORT} is closed, retrying in ${TIMER:-5} seconds ($i)" >> $LOG_FILE_PATH/install_temp.log
            sleep ${TIMER:-5}
        fi
    done

    netstat -anp |grep $mysql_port
    if [ $? -eq 0 ]; then
	sudo sed -i '1,$d' ${CHROOT_PACKAGE_DIR}/config/mysql_init
        sudo sed -i '1,$d' ${CHROOT_PACKAGE_DIR}/bin/mysqlaccess.conf
    else
        echo "mysql start up failed" >> $LOG_FILE_PATH/install_temp.log
        sudo sed -i '1,$d' ${CHROOT_PACKAGE_DIR}/config/mysql_init
        sudo sed -i '1,$d' ${CHROOT_PACKAGE_DIR}/bin/mysqlaccess.conf
        exit
    fi
    #sudo chmod 700 $CHROOT_PACKAGE_DIR/mysqld.sock
    return $RESULT_OK
}

function install_etcd()
{
    PACKAGE_DIR=/var/paas/etcd/bin
    mkdir -p ${PACKAGE_DIR}
    cp /var/paas/packages/package/$version/common/etcd.tgz ${PACKAGE_DIR}
    cd ${PACKAGE_DIR}
    tar xzf etcd.tgz -C $PACKAGE_DIR
    rm etcd.tgz

    ETCD_CTL_DIR=/var/paas/jobs/etcd/bin
    mkdir -p ${ETCD_CTL_DIR}
    cp $ROOTPATH/monitfile/etcd/etcd_ctl ${ETCD_CTL_DIR}
    sed -i "s|<%= SINGLE_ETCD_IP %>|$HOST_IP|g" ${ETCD_CTL_DIR}/etcd_ctl
    chmod -R 750 ${ETCD_CTL_DIR}
    chmod 700 ${ETCD_CTL_DIR}/*

    etcd_monitrc_path="/var/paas/monit/job"
    mkdir -p ${etcd_monitrc_path}
    chmod -R 750 ${etcd_monitrc_path}
    cp $ROOTPATH/monitfile/etcd/etcd.monitrc ${etcd_monitrc_path}
    chmod 640 ${etcd_monitrc_path}/*

    export UMASK=0600
    export UMASK_DIR=0700
    bash /var/paas/jobs/etcd/bin/etcd_ctl start
    sleep 1
    /var/paas/monit/bin/monit reload

    netstat -anp |grep 5678
    if [ $? != 0 ]; then
       echo "etcd start up failed" >> $LOG_FILE_PATH/install_temp.log
       return $RESULT_ERROR
    fi
    return $RESULT_OK
}

# skydns depends on etcd
function install_skydns()
{
    PACKAGE_DIR=/var/paas/skydns/bin
    mkdir -p ${PACKAGE_DIR}
    cp /var/paas/packages/package/$version/common/skydns.tar.gz ${PACKAGE_DIR}
    cd ${PACKAGE_DIR}
    tar xzf skydns.tar.gz -C $PACKAGE_DIR
    rm skydns.tar.gz

    skydns_ctl_dir=/var/paas/jobs/skydns/bin
    mkdir -p ${skydns_ctl_dir}
    cp $ROOTPATH/monitfile/skydns/skydns_ctl ${skydns_ctl_dir}
    cp $ROOTPATH/monitfile/skydns/init.sh ${skydns_ctl_dir}
    sed -i "s|<%= SINGLE_ETCD_IP %>|$HOST_IP|g" ${skydns_ctl_dir}/skydns_ctl
    sed -i "s|<%= SINGLE_ETCD_IP %>|$HOST_IP|g" ${skydns_ctl_dir}/init.sh
    sed -i "s|<%= SKYDNS_IP %>|$HOST_IP|g" ${skydns_ctl_dir}/init.sh
    sed -i "s|<%= NAMESERVER_IP %>|$nameserver_ip|g" ${skydns_ctl_dir}/init.sh
    chmod -R 750 ${skydns_ctl_dir}
    chmod 700 ${skydns_ctl_dir}/*

    skydns_monitrc_path="/var/paas/monit/job"
    mkdir -p ${skydns_monitrc_path}
    chmod -R 750 ${skydns_monitrc_path}
    cp $ROOTPATH/monitfile/skydns/skydns.monitrc ${skydns_monitrc_path}
    sed -i "s|<%= SKYDNS_IP %>|$HOST_IP|g" ${skydns_monitrc_path}/skydns.monitrc
    chmod 640 ${skydns_monitrc_path}/*

    export UMASK=0600
    export UMASK_DIR=0700
    bash /var/paas/jobs/skydns/bin/init.sh
    bash /var/paas/jobs/skydns/bin/skydns_ctl start
    sleep 1
    /var/paas/monit/bin/monit reload
    netstat -anp |grep 53
    if [ $? != 0 ]; then
       echo "skydns start up failed" >> $LOG_FILE_PATH/install_temp.log
       exit
    fi
    return $RESULT_OK
}

function start_monit_celery()
{
    celery_ctl_path=/var/paas/jobs/celery/cloudify.management__worker/env/bin
    if [ ! -d ${celery_ctl_path} ]; then
        mkdir -p ${celery_ctl_path}
        chmod -R 750 ${celery_ctl_path}
    fi
    cp $ROOTPATH/monitfile/celery/celery_ctl ${celery_ctl_path}
    chmod -R 750 ${celery_ctl_path}
    chmod 700 ${celery_ctl_path}/*

    celery_monitrc_path="/var/paas/monit/job"
    if [ ! -d ${celery_monitrc_path} ]; then
        mkdir -p ${celery_monitrc_path}
        chmod -R 750 ${celery_monitrc_path}
    fi
    cp $ROOTPATH/monitfile/celery/celery.monitrc ${celery_monitrc_path}
    chmod 640 ${celery_monitrc_path}/*
    /var/paas/jobs/celery/cloudify.management__worker/env/bin/celery_ctl stop
    sleep 1
    /var/paas/jobs/celery/cloudify.management__worker/env/bin/celery_ctl start
    sleep 1
    /var/paas/monit/bin/monit reload
}


function install_nginx()
{
    echo -ne "install nginx..."
    
    sudo mkdir -p /var/log/nginx
    sudo mkdir -p /var/cache/nginx
    mkdir -p /var/paas/jobs/nginx/
    mkdir -p /var/paas/sys/run/nginx
    mkdir -p /var/paas/sys/log/nginx

    NGINX_PKG=/var/paas/jobs/nginx
    tar zxvf /var/paas/packages/package/$version/cloudify/nginx-rpm.tgz -C $NGINX_PKG
    sudo rpm -i --force $NGINX_PKG/nginx/dependence/*.rpm
    sudo rpm -i --force $NGINX_PKG/nginx/nginx-1.6.3-6.el7.x86_64.rpm
    if [ ! -f "/etc/init.d/nginx" ]; then
      sudo cp $NGINX_PKG/nginx/nginx /etc/init.d/
    fi
    rm -rf $NGINX_PKG/nginx/nginx

    echo -e "applying nginx config..."
    sudo cp $ROOTPATH/nginx/config/nginx.conf /etc/nginx/nginx.conf
    sudo cp $ROOTPATH/nginx/config/default.conf /etc/nginx/conf.d
    sudo sed -i "s/*:7777/$HOST_IP:7777/g" /etc/nginx/conf.d/default.conf
    sudo cp /etc/init.d/nginx /var/paas/jobs/nginx/nginx_server
    sudo sed -i "s|/var/run|/var/paas/sys/run/nginx|" /var/paas/jobs/nginx/nginx_server

    sudo /etc/init.d/nginx stop
    rm -rf /etc/init/nginx.conf
    rm -rf /etc/init.d/nginx
    
    echo -e "starting nginx..."
    sudo chown -R paas:paas /var/lib/nginx
    sudo chown -R paas:paas /etc/nginx
    sudo chown -R paas:paas /run/lock
    sudo chown -R paas:paas /var/lock
    sudo chown paas:paas -R /var/cache/nginx
    sudo chown paas:paas -R /var/log/nginx/
    sudo chown paas:paas -R /var/paas/sys/log/nginx
    sudo chown paas:paas -R /var/paas/jobs/nginx
    sudo chown paas:paas -R /var/paas/sys/run/nginx
    sudo chmod g-w,o-rwx -R /var/cache/nginx
    sudo chmod g-wx,o-rwx -R /var/paas/sys/log/nginx
    sudo chmod g-w,o-rwx -R /var/paas/jobs/nginx
    sudo chmod g-wx,o-rwx -R /var/paas/sys/run/nginx
    sudo su paas -c "bash /var/paas/jobs/nginx/nginx_server start"
    
    nginx_ctl_path=/var/paas/jobs/nginx/bin
    if [ ! -d ${nginx_ctl_path} ]; then
        mkdir -p ${nginx_ctl_path}
        chmod -R 750 ${nginx_ctl_path}
    fi
    cp $ROOTPATH/monitfile/nginx/nginx_ctl ${nginx_ctl_path}
    chmod -R 750 ${nginx_ctl_path}
    chmod 700 ${nginx_ctl_path}/*

    nginx_monitrc_path="/var/paas/monit/job"
    if [ ! -d ${nginx_monitrc_path} ]; then
        mkdir -p ${nginx_monitrc_path}
        chmod -R 750 ${nginx_monitrc_path}
    fi
    cp $ROOTPATH/monitfile/nginx/nginx.monitrc ${nginx_monitrc_path}
    chmod 640 ${nginx_monitrc_path}/*
    /var/paas/jobs/nginx/bin/nginx_ctl start
    sleep 1
    /var/paas/monit/bin/monit reload
}
function install_manager()
{
    tar zxf /var/paas/packages/package/$version/common/crypto.tgz -C /var/paas
    mv /var/paas/output/crypto_tool /var/paas/
    sudo cp -pr /var/paas/output/* /usr/lib64/
    cp -r $ROOTPATH/code/celery /var/paas/

    install_nginx

    echo "{\"username\": \"iaas_keystone_username\", \"tenant_name\": \"iaas_keystone_tenant_name\", \"region\": \"iaas_region\", \"nova_url\": \"\", \"auth_url\": \"iaas_keystone_url\", \"password\": \"iaas_keystone_password\", \"neutron_url\": \"\"}" > /home/paas/${iaasname}_config.json
    sed -i "s|iaas_keystone_username|$iaas_keystone_username|g" /home/paas/${iaasname}_config.json >> /dev/null 2>&1
    sed -i "s|iaas_keystone_tenant_name|$iaas_keystone_tenant_name|g" /home/paas/${iaasname}_config.json >> /dev/null 2>&1
    sed -i "s|iaas_region|$iaas_region|g" /home/paas/${iaasname}_config.json >> /dev/null 2>&1
    sed -i "s|iaas_keystone_url|$iaas_keystone_url|g" /home/paas/${iaasname}_config.json >> /dev/null 2>&1
    iaas_keystone_password_crypto=`/var/paas/crypto_tool -text ${iaas_keystone_password}`
    sed -i "s|iaas_keystone_password|$iaas_keystone_password_crypto|g" /home/paas/${iaasname}_config.json >> /dev/null 2>&1
    chown paas:paas  /home/paas/${iaasname}_config.json

    cd /var/paas
    chmod 600 *.txt *.log  celery
    chmod 700 crypto_tool
    tar zcf keystore.tgz primary_keystore.txt standby_keystore.txt crypto_tool celery
    cd /var/paas/output
    tar zcf libs.tgz *
    mkdir -p /var/paas/crypto_libs
    cp -r /var/paas/output/libs.tgz /var/paas/crypto_libs/
    cp -r /var/paas/keystore.tgz /var/paas/crypto_libs/
    sudo chown paas:paas /var/paas/*.log
    sudo chown paas:paas /var/paas/*.txt

    rm -rf /var/paas/output
    rm -rf /var/paas/keystore.tgz
    rm -rf /var/paas/celery

    sudo chmod g-w,o-rwx -R /var/paas/crypto_libs/

    return $RESULT_OK
}

function uninstall_monit()
{
    rm -rf /var/paas/monit/
    rm -rf /var/paas/scripts/utils
}
# **************************************************************************** #
# Function    : create_http_service
# Description : create_http_service
# Parameter   : $1 - title string you want to display
# Return      : none
# Since       : Foundation PaaS V100R001C00
# Others      : w00241627
# **************************************************************************** #

function uninstall()
{
    if [ "$mode" = "" ] || [ "$mode" = "manager" ]; then
        uninstall_manager >>$LOG_FILE_PATH/uninstall_temp.log 2>&1
        if [ $? -ne 0 ] ; then
            print_log_to_screen "uninstall manager" "$fTAG"
            return $RESULT_ERROR
        fi
        print_log_to_screen "uninstall manager" "$sTAG"
        rm -rf $ROOTPATH/manager_done
    fi
    if [ "$mode" = "" ] || [ "$mode" = "deploy_rest_server" ]; then
        uninstall_deploy_rest_server >>$LOG_FILE_PATH/uninstall_temp.log 2>&1
        if [ $? -ne 0 ] ; then
            print_log_to_screen "uninstall deploy_rest_server" "$fTAG"
            return $RESULT_ERROR
        fi
        print_log_to_screen "uninstall deploy_rest_server" "$sTAG"
        rm -rf $ROOTPATH/deploy_rest_server_done
    fi
    if [ "$mode" = "" ] || [ "$mode" = "mysql" ]; then
        uninstall_mysql >>$LOG_FILE_PATH/uninstall_temp.log 2>&1
        if [ $? -ne 0 ] ; then
            print_log_to_screen "uninstall mysql" "$fTAG"
            return $RESULT_ERROR
        fi
        print_log_to_screen "uninstall mysql" "$sTAG"
        rm -rf $ROOTPATH/mysql_done
    fi
    if [ "$mode" = "" ] || [ "$mode" = "etcd" ]; then
        uninstall_etcd >>$LOG_FILE_PATH/uninstall_temp.log 2>&1
        if [ $? -ne 0 ] ; then
            print_log_to_screen "uninstall etcd" "$fTAG"
            return $RESULT_ERROR
        fi
        print_log_to_screen "uninstall etcd" "$sTAG"
        rm -rf $ROOTPATH/etcd_done
    fi
    if [ "$mode" = "" ] || [ "$mode" = "skydns" ]; then
        uninstall_skydns >>$LOG_FILE_PATH/uninstall_temp.log 2>&1
        if [ $? -ne 0 ] ; then
            print_log_to_screen "uninstall skydns" "$fTAG"
            return $RESULT_ERROR
        fi
        print_log_to_screen "uninstall skydns" "$sTAG"
        rm -rf $ROOTPATH/skydns_done
    fi
    if [ "$mode" = "" ] || [ "$mode" = "monit" ]; then
        uninstall_monit >>$LOG_FILE_PATH/uninstall_temp.log 2>&1
        if [ $? -ne 0 ] ; then
            print_log_to_screen "uninstall monit" "$fTAG"
            return $RESULT_ERROR
        fi
        print_log_to_screen "uninstall monit" "$sTAG"
        rm -rf $ROOTPATH/monit_done
    fi
    if [ "$mode" = "" ] || [ "$mode" = "salt" ]; then
        uninstall_salt >>$LOG_FILE_PATH/uninstall_temp.log 2>&1
        if [ $? -ne 0 ] ; then
            print_log_to_screen "uninstall salt" "$fTAG"
            return $RESULT_ERROR
        fi
        print_log_to_screen "uninstall salt" "$sTAG"
        rm -rf $ROOTPATH/salt_done
    fi

    return $RESULT_OK
}

function uninstall_package()
{
    if (command -v dpkg); then
        sudo dpkg -r $1
        sudo dpkg --purge $1
    fi

    if (command -v rpm); then
        sudo rpm -e $1
    fi
}
function uninstall_manager()
{
    bash /var/paas/jobs/manager/manager.conf stop
    sudo rm -rf /var/paas/jobs/manager
    sudo stop celeryd-cloudify-management
    sudo rm -rf /var/paas/jobs/celery

    sudo pip uninstall -q -y virtualenv

    /var/paas/jobs/nginx/nginx_server stop 
    uninstall_package nginx
    rm -rf /var/paas/jobs/nginx
    mv /var/paas/jobs/rabbitmq/bin/rabbitmq_ctl /var/paas/jobs/rabbitmq/bin/rabbitmq_ctl_bak
    /var/paas/jobs/rabbitmq/bin/rabbitmq_ctl_bak stop
    rm -rf /var/paas/jobs/rabbitmq/

    sudo stop elasticsearch
    uninstall_package elasticsearch
    mv /var/paas/jobs/elasticsearch_cloudify/bin/elasticsearch_cloudify_ctl /var/paas/jobs/elasticsearch_cloudify/bin/elasticsearch_cloudify_ctl_bak
    /var/paas/jobs/elasticsearch_cloudify/bin/elasticsearch_cloudify_ctl_bak stop
    sudo rm -rf /var/paas/jobs/elasticsearch*

    uninstall_package logstash
    sudo rm -rf /var/paas/jobs/logstash*

    sudo kill `lsof -t -i:9999`
    sudo rm -rf /var/paas/jobs/logstash
    sudo rm -rf /var/paas/aes_crypto.py*
    sudo rm -rf /var/paas/logstash_dec.py


    sudo kill `sudo lsof -t -i:9200`
    sudo rm -rf /var/paas/elasticsearch
    sudo rm -rf /etc/init.d/elasticsearch
    sudo update-rc.d -f elasticsearch remove

    sudo rm -rf /agents
    sudo rm -rf /cloudify-core
    sudo rm -rf /cloudify-components
    sudo rm -rf /etc/default/celeryd*
    sudo rm -rf /etc/init.d/celeryd*
    sudo rm -rf /home/paas/*_config.json
    sudo rm -rf /home/paas/cloudify*
    sed -i "s/management=$management/management=/g" $ROOTPATH/../config/ipinfo
    return $RESULT_OK
}

function uninstall_deploy_rest_server()
{   
    deploy_rest_server_root=/var/paas/deploy_rest_server
    deploy_rest_server_ctl_path=/var/paas/jobs/deploy_rest_server/bin
    RUN_DIR=/var/paas/sys/run/deploy_rest_server
    LOG_DIR=/var/paas/sys/log/deploy_rest_server
    /var/paas/jobs/deploy_rest_server/bin/deploy_rest_server_ctl stop 
    sudo rm -rf ${deploy_rest_server_ctl_path}
    sudo rm -rf ${deploy_rest_server_root}
    sudo rm -rf ${RUN_DIR}
    sudo rm -rf ${LOG_DIR}
    return $RESULT_OK
}

function uninstall_mysql()
{
    PACKAGE_DIR=/var/vcap/packages/mysql
    TMP_DIR=$PACKAGE_DIR/tmp
    DATA_DIR=/var/vcap/store/mysql
    LOG_BIN_DIR=/var/vcap/store/mysql-logs
    RUN_DIR=/var/vcap/sys/run/mysql
    LOG_DIR=/var/vcap/sys/log/mysql
    monitrc_path=/var/paas/monit/job
    mysql_ctl_path=/var/paas/jobs/mysql/bin
    bash /var/paas/jobs/mysql/bin/mysql_ctl stop
    sudo rm -rf ${PACKAGE_DIR}
    sudo rm -rf ${TMP_DIR}
    sudo rm -rf ${DATA_DIR}
    sudo rm -rf ${LOG_BIN_DIR}
    sudo rm -rf ${RUN_DIR}
    sudo rm -rf ${LOG_DIR}
    sudo rm -rf ${monitrc_path}
    sudo rm -rf ${mysql_ctl_path}
    sudo rm -rf ${mysql_chroot_dir}
   if [ "${mysql_user}" != "paas" ]; then
      sudo userdel -r -f ${mysql_user}
   fi

    return $RESULT_OK
}

function uninstall_etcd()
{
    PACKAGE_DIR=/var/paas/etcd
    DATA_DIR=/var/paas/store/etcd
    RUN_DIR=/var/paas/sys/run/etcd
    LOG_DIR=/var/paas/sys/log/etcd
    monitrc_path=/var/paas/monit/job
    etcd_ctl_path=/var/paas/jobs/etcd/bin
    /var/paas/jobs/etcd/bin/etcd_ctl stop
    rm -rf ${PACKAGE_DIR}
    rm -rf ${DATA_DIR}
    rm -rf ${RUN_DIR}
    rm -rf ${LOG_DIR}
    rm -rf ${monitrc_path}/etcd.monitrc
    rm -rf ${etcd_ctl_path}
    return $RESULT_OK
}

function uninstall_skydns()
{
    PACKAGE_DIR=/var/paas/skydns
    RUN_DIR=/var/paas/sys/run/skydns
    LOG_DIR=/var/paas/sys/log/skydns
    monitrc_path=/var/paas/monit/job
    skydns_ctl_path=/var/paas/jobs/skydns/bin
    /var/paas/jobs/skydns/bin/skydns_ctl stop
    rm -rf ${PACKAGE_DIR}
    rm -rf ${RUN_DIR}
    rm -rf ${LOG_DIR}
    rm -rf ${monitrc_path}/skydns.monitrc
    rm -rf ${skydns_ctl_path}
    return $RESULT_OK
}

source $ROOTPATH/../config/commoninfo.ini

if [ ! -f $ROOTPATH/../config/config.ini ]; then
    echo -e "config/config.ini is missing               \033[31;49;1m[FATAL]\033[0m"  
    exit $RESULT_ERROR
fi

source $ROOTPATH/../config/config.ini

while [ "$1" != "" ]; do
    case "$1" in
        "install" | "uninstall" | "status" )
            operate="$1"
            if [ "$2" != "" ]; then
                mode="$2"
                shift 1
            fi
            ;;
        "-?" | "--help" )
            print_help
            exit $RESULT_OK
            ;;
        * )
            echo -e "parameter " $1 " invalid. use patameter --help to get help."  
            exit $PARAMETER_ERROR
            ;;
    esac

    shift
done

if [ -z "$operate" ]; then
    echo -e "parameter error. use patameter --help to get help."
    exit $PARAMETER_ERROR
fi

case "$operate" in
    "install" )
        install
        if [ $? -ne 0 ]; then
            exit $RESULT_ERROR
        fi
        ;;
    "uninstall" )
        uninstall
        if [ $? -ne 0 ]; then
            exit $RESULT_ERROR
        fi
        ;;
    * ) 
        echo -e "parameter invalid. use parameter --help to get help."
        exit $PARAMETER_ERROR
        ;;
esac
