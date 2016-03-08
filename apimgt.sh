#!/bin/bash

# //////////////////////////////////////////////////////////////////////////// #
#                                                                              #
#  description : install, uninstall, start, stop gaussdb                     #
#  create Date : 2015/09/19                                                    #
#  Author      : w00241627, c00284974                                          #
#  Since       : Foundation PaaS API-MANAGEMENT V100R001C00                    #
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
verbose=""
operate=""
slience=0

gs_package="GaussDB-*.tar.gz"
value=""

RESULT_OK=0
RESULT_ERROR=1
PARAMETER_ERROR=2
USER_REJECTED=3
BUILD_ERROR=6

RESULT_SUCCESS=0
RESULT_FAILURE=1
PARAMETERS_ERR=2
RESULT_REOPRATION=9
DATE=$(date +%Y%m%d)
ROOTPATH=$(cd "$(dirname "$0")"; pwd)
user_name=gaussdb
user_grp=dbgrp
jdk_version=jdk
jdk_path=/opt/$user_name/$jdk_version
java_path=/opt/$user_name/$jdk_version/bin
crypto_jar=$ROOTPATH/install/com.huawei.am.igt.pwdjobexecutor-1.0.0.jar
ret=" "
# The default system log for shell 
LOG_SYSTEM_PATH=/var/log

    
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
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      :
# **************************************************************************** #
function print_help()
{
echo -e "
    $UTILITY_NAME is a UTILITY to install/uninstall and start/stop gaussdb server.
    
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
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
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
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
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
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
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
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
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

# **************************************************************************** #
# Function    : print_title
# Description : print_title
# Parameter   : $1 - title string you want to display
# Return      : none
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
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

# //////////////////////////////////////////////////////////////////////////// #
#                                                                              #
#                                Common Function                               #
#                                                                              #
# //////////////////////////////////////////////////////////////////////////// #


# **************************************************************************** #
# Function    : read_xml
# Description : show the information if verbose is set
# Parameter   : $1 -- information
# Return      : none
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
# **************************************************************************** #

function read_xml()
{
    xml_file="$ROOTPATH/configure/properties.xml"

    if [ "$1" = "" ]; then
        echo -e "please input a parameter"
        return
    fi

    eval "line=\`sed -n '/$1/=' $xml_file\`"

    if [ "$line" = "" ]; then
        echo -e "can't find \"$1\""
        return
    fi

    line=`sed -n ${line}p $xml_file`

    line=${line#*>}
    line=${line%%<*}

    echo $line
}

# //////////////////////////////////////////////////////////////////////////// #
#                                                                              #
#                               Install Apimgt                                 #
#                                                                              #
# //////////////////////////////////////////////////////////////////////////// #

# **************************************************************************** #
# Function    : create_user_and_group
# Description : create_user_and_group
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      :
# **************************************************************************** #

function create_user_and_group()
{
  if [ ! -d /opt/gaussdb/ ];then
   mkdir -p /opt/gausstemp
		
   cp $ROOTPATH/../gaussdb/jdk.tar.gz /opt/gausstemp/
   cd /opt/gausstemp
   tar zxvf jdk.tar.gz  >> /dev/null 2>&1
		
   cd $ROOTPATH/../

   chmod +x $ROOTPATH/../gaussdb/install/get_password.sh
   iotGaussdbaPassword=$(sh $ROOTPATH/../gaussdb/install/get_password.sh -a OS.user.gaussdba.password)
   iotTopusPassword=$(sh $ROOTPATH/../gaussdb/install/get_password.sh -a OS.user.topus.password)
   echo "#!/bin/bash" > $ROOTPATH/scripts/common/temp.sh
   chmod +x $ROOTPATH/scripts/common/temp.sh
  result=`/opt/gausstemp/jdk/bin/java -jar $crypto_jar "iotGaussdbaPassword=$iotGaussdbaPassword&iotTopusPassword=$iotTopusPassword" $ROOTPATH/scripts/common/usrmgt_create.sh $ROOTPATH/../gaussdb/install/crypto 2>> /dev/null`
   result=$?
   rm -rf /opt/gausstemp
   cd $ROOTPATH
  else
   chmod +x $ROOTPATH/../gaussdb/install/get_password.sh
   iotGaussdbaPassword=$(sh $ROOTPATH/../gaussdb/install/get_password.sh -a OS.user.gaussdba.password)
   iotTopusPassword=$(sh $ROOTPATH/../gaussdb/install/get_password.sh -a OS.user.topus.password)
   echo "#!/bin/bash" > $ROOTPATH/scripts/common/temp.sh
   chmod +x $ROOTPATH/scripts/common/temp.sh
 result=`$java_path/java -jar $crypto_jar "iotGaussdbaPassword=$iotGaussdbaPassword&iotTopusPassword=$iotTopusPassword" $ROOTPATH/scripts/common/usrmgt_create.sh $ROOTPATH/../gaussdb/install/crypto 2>>/dev/null`
   result=$?
  fi
  if [ $result -ne $RESULT_SUCCESS ];then       
    print_log_to_screen "create gaussdb" "$FTAG"       
    return $result    
  fi     
	groupmod  topus -g 2000
	usermod  topus -u 2000
	usermod -g topus topus
    print_log_to_screen "create gaussdb" "$STAG"   
    return $RESULT_SUCCESS
}
# **************************************************************************** #
# Function    : copy_files_for_gaussdba
# Description : copy_files_for_gaussdba
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      :
# **************************************************************************** #

function copy_files_for_gaussdba()
{ 
    print_log_to_screen "create /opt/gaussdb"
    if [ ! -d /opt/gaussdb ]; then
        mkdir -p /opt/gaussdb
    fi
    chown gaussdba:dbgrp -R /opt/gaussdb
    chmod u+rx /opt/gaussdb
    echo -e "$sTAG"
    
    print_log_to_screen "create /opt/gaussdb/log"
    if [ ! -d /opt/gaussdb/log ]; then
        mkdir -p /opt/gaussdb/log       
    fi
    chown gaussdba:dbgrp -R /opt/gaussdb/log
    echo -e "$sTAG"
	
	print_log_to_screen "create /log/gaussdb/log"
	if [ ! -d /log/gaussdb/log ]; then
        mkdir -p /log/gaussdb/log       
    fi
    chown gaussdba:dbgrp -R /log/gaussdb/log
    echo -e "$sTAG"
	
	print_log_to_screen "create /log/gaussdb/log"
	if [ ! -d /log/gaussdb/log ]; then
        mkdir -p /log/gaussdb/log       
    fi
    chown gaussdba:dbgrp -R /log/gaussdb
    echo -e "$sTAG"
	
    print_log_to_screen "copy script, configure "
    cp -r $ROOTPATH/scripts /opt/gaussdb >> /dev/null 2>&1
    cp -r $ROOTPATH/configure /opt/gaussdb >> /dev/null 2>&1
    cp -f $ROOTPATH/apimgt.sh /opt/gaussdb >> /dev/null 2>&1
	cp -r $ROOTPATH/configure/shell-log4j.properties /opt/topus/configure >> /dev/null 2>&1
    chown gaussdba:dbgrp -R /opt/gaussdb/configure 
    chown gaussdba:dbgrp -R /opt/gaussdb/scripts
	#chown -R topus:topus /opt/gaussdb/apigw
	mkdir -p /opt/topus/apimgt/repository/conf/datasources >> /dev/null 2>&1
	cp -f $ROOTPATH/gaussmgt/datasources/master-datasources.xml /opt/topus/apimgt/repository/conf/datasources/
	chown -R topus:topus /opt/topus/apimgt/repository/conf/datasources/
    echo -e "$sTAG"
    print_log_to_screen "copy file for gaussdb" "$STAG"
    return $RESULT_SUCCESS
}
# **************************************************************************** #
# Function    : install_java
# Description : install jdk
# Parameter   : $1 -- information
# Return      : none
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      :
# **************************************************************************** #
function install_java()
{    
    print_log_to_screen "install $jdk_version ..."
    
    if [ ! -d $jdk_path ]; then
        if [ -f $jdk_version.tar.gz ]; then
            tar zxvf $jdk_version.tar.gz >> /dev/null 2>&1
			mkdir -p /opt/$user_name/
            mv $jdk_version /opt/$user_name/
            
            command_pre="[[ ! \$LD_LIBRARY_PATH =~ \"$jdk_path/lib\" ]]"
            command_sub="sed -i '\$a export LD_LIBRARY_PATH=\"$jdk_path/lib\":\$LD_LIBRARY_PATH' ~/.bashrc"
            su - gaussdba -c "${command_pre} && ${command_sub}"
            su - gaussdba -c "sed -i '/JAVA_HOME/d' ~/${profilename}"   >> /dev/null 2>&1
            su - gaussdba -c "echo 'export JAVA_HOME=$jdk_path' >> ~/${profilename}" >> /dev/null 2>&1
            su - gaussdba -c "echo 'export PATH=\$JAVA_HOME/bin:\$PATH' >> ~/${profilename}" >> /dev/null 2>&1
            su - gaussdba -c "echo 'export CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar' >> ~/${profilename}" >> /dev/null 2>&1

            chown gaussdba $jdk_path -R
            chgrp $user_grp $jdk_path -R
            chmod o-rwx $jdk_path -R
        else
            echo -e "$fTAG : $jdk_version.tar.gz missing"
            return $RESULT_FAILURE
        fi
    else 
        echo -e "$fTAG : already existed"   
        return $RESULT_FAILURE
    fi
    echo -e "$sTAG"
    
    print_log_to_screen "install Java" "$STAG"
    return $RESULT_SUCCESS
}

# **************************************************************************** #
# Function    : install_gaussdb
# Description : install_gaussdb
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      :
# **************************************************************************** #

function install_gaussdb()
{
    if [ "$active_mode" == "stand-alone" ]; then
        $ROOTPATH/scripts/database/gaussdb.sh install \
           -P $ROOTPATH/$gs_package
    else
        $ROOTPATH/scripts/database/gaussdb.sh install \
           -P $ROOTPATH/$gs_package -M $active_mode
    fi
    if [ $? -ne 0 ]; then
        return $RESULT_FAILURE
        print_log_to_screen "install GaussDB" "$FTAG"
    fi
    
    print_log_to_screen "install GaussDB" "$STAG"
    return $RESULT_SUCCESS
}

# **************************************************************************** #
# Function    : initial_gaussdb
# Description : initial_gaussdb
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function initial_gaussdb()
{
    print_log_to_screen "start gaussdb ..."
    $ROOTPATH/scripts/database/gaussdb.sh start $verbose > /dev/null
    if [ $? -ne 0 ]; then
        echo -e "$fTAG"
        return $RESULT_FAILURE
    fi
    echo -e "$sTAG"
    su - gaussdba -c "gs_guc reload -c 'password_reuse_max=1';" >> /dev/null 2>&1
	if [ $? -ne 0 ]; then
        echo -e "$fTAG"
        return $RESULT_FAILURE
    fi
    print_log_to_screen "initial gaussdb ..."
    userApimgtdbPassword=$(sh $ROOTPATH/install/get_password.sh -a DB.user.apimgtdb.password)
    echo "#!/bin/bash" > $ROOTPATH/scripts/database/temp.sh
    chmod u+x $ROOTPATH/scripts/database/temp.sh
    result=`$java_path/java -jar $crypto_jar "userApimgtdbPassword=$userApimgtdbPassword" $ROOTPATH/scripts/database/init_db.sh $ROOTPATH/install/crypto 2>> /dev/null`
    ret=$?
    if [ $ret -ne 0 ]; then
        echo -e "$fTAG"
        $ROOTPATH/scripts/database/gaussdb.sh stop $verbose > /dev/null
        if [ $? -ne 0 ]; then
            echo -e "$fTAG"
            return $RESULT_FAILURE
        fi
        return $RESULT_FAILURE
    fi
    echo -e "$sTAG"
    
    print_log_to_screen "stop gaussdb ..."
    $ROOTPATH/scripts/database/gaussdb.sh stop $verbose > /dev/null
    if [ $? -ne 0 ]; then
        echo -e "$fTAG"
        return $RESULT_FAILURE
    fi
    echo -e "$sTAG"

    print_log_to_screen "initial GaussDB" "$STAG"
    return $RESULT_SUCCESS
}
# **************************************************************************** #
# Function    : check_before_install
# Description : check_before_install
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function check_before_install()
{
    #Check the information of the system and the configuration of the gaussdba
    $ROOTPATH/scripts/system/check_before_install.sh -c $ROOTPATH/configure/check.ini -o $ROOTPATH/configure/config.ini -p $ROOTPATH/configure/properties.xml
    if [ $? -ne 0 ]
    then
        exit $RESULT_ERROR
    fi
}

# **************************************************************************** #
# Function    : install
# Description : install api mgt to the OS
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function install()
{
    local logfile=$LOG_SYSTEM_PATH/gaussdb_install.log
    echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] install API-MGT started" > $logfile

    local step=0
    local step_num=5
    install_check
    if [ $? -ne 0 ]; then
        print_log_to_screen "install system" "$FTAG : system is already installed!"
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] system is already installed" >> $logfile
        exit $RESULT_REOPRATION
    fi
    
    print_title "Install GaussDB"
     
    sed -i '/ulimit -HSn 240000/d' /etc/profile 
    echo "ulimit -HSn 240000" >> /etc/profile
    source /etc/profile

    step=`expr $step + 1`
    print_progress $step $step_num "create gaussdb "
    create_user_and_group
    local result=$?
    if [ $result -ne $RESULT_SUCCESS ]; then
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] create gaussdb user failed" >> $logfile
        return $result
    else
        echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] create gaussdb user success" >> $logfile
    fi
	
    step=`expr $step + 1`
    print_progress $step $step_num "copy file"
    copy_files_for_gaussdba
    if [ $? -ne $RESULT_SUCCESS ]; then
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] copy file failed" >> $logfile
        return $RESULT_FAILURE
    else
        echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] copy file success" >> $logfile
    fi
	
    step=`expr $step + 1`
    print_progress $step $step_num "install Java"
    install_java
    if [ $? -ne $RESULT_SUCCESS ]; then
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] install Java failed" >> $logfile
        return $RESULT_FAILURE
    else
        echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] install Java success" >> $logfile
    fi

    step=`expr $step + 1`
    print_progress $step $step_num "install GaussDB"
    install_gaussdb
    if [ $? -ne $RESULT_SUCCESS ]; then
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] install GaussDB failed" >> $logfile
        return $RESULT_FAILURE
    else
        echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] install GaussDB success" >> $logfile
    fi    
	
    step=`expr $step + 1`
    print_progress $step $step_num "initial GaussDB"
    initial_gaussdb
    if [ $? -ne $RESULT_SUCCESS ]; then
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] initial GaussDB failed" >> $logfile
        return $RESULT_FAILURE
    else
        echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] initial GaussDB success" >> $logfile
    fi   
    chown gaussdba:dbgrp /opt/gaussdb/log >> /dev/null 2>&1
    chown gaussdba:dbgrp -R /opt/gaussdb/log/jar >> /dev/null 2>&1
    rm -rf $ROOTPATH/install/crypto/material.txt >> /dev/null 2>&1
    rm -rf $ROOTPATH/install/crypto/working_key.txt >> /dev/null 2>&1
    
    print_title "Install Gaussdb Successful"
    echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] Install Gaussdb Successful" >> $logfile
    return $RESULT_SUCCESS 
	
}

# **************************************************************************** #
# Function    : uninstall_gaussdb
# Description : uninstall_gaussdb
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function uninstall_gaussdb()
{
    if [ ! "$active_mode" = "stand-alone" ];then
        $ROOTPATH/scripts/database/gaussdb.sh uninstall -M $active_mode
    else
        $ROOTPATH/scripts/database/gaussdb.sh uninstall
    fi
    if [ $? -ne 0 ]; then
        return $RESULT_ERROR
    fi
    
    return $RESULT_OK
}

# **************************************************************************** #
# Function    : uninstall_dependency
# Description : uninstall_dependency
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function uninstall_check()
{
    ret=$RESULT_OK
    if [ -d /home/gaussdba ]; then
        print_log_to_screen "remove /home/gaussdba" "$FTAG"
        ret=$RESULT_ERROR
    fi
    if [ -d /opt/gaussdba ]; then
        print_log_to_screen "remove /opt/gaussdba" "$FTAG"
        ret=$RESULT_ERROR
    fi
    
    if [ ! "$database_data_path" = "" ]; then
        if [ -d $database_data_path ]; then
            print_log_to_screen "remove $database_data_path" "$FTAG"
            ret=$RESULT_ERROR
        fi
    else
        if [ -d /data/gaussdb ]; then
            print_log_to_screen "remove /data/gaussdb" "$FTAG"
            ret=$RESULT_ERROR
        fi 
    fi
    
    return $ret   
}

# **************************************************************************** #
# Function    : uninstall_java
# Description : uninstall_java
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function uninstall_java()
{
    if [ -d $jdk_path ]; then
        rm -rf $jdk_path >> /dev/null 2>&1
        su - gaussdba -c "sed -i '/jdk/d' ~/.bashrc" >> /dev/null 2>&1
        su - gaussdba -c "sed -i '/JAVA_HOME/d' ~/.bash_profile" >> /dev/null 2>&1
    fi
    
    print_log_to_screen "uninstall java" "$STAG"
}

# **************************************************************************** #
# Function    : uninstall_user
# Description : uninstall_user
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function uninstall_user()
{
    $ROOTPATH/scripts/common/usrmgt.sh -d $verbose
    if [ $? -ne 0 ];then
        return $RESULT_ERROR
    fi
    sed -i '/topus/d' /etc/exports >> /dev/null 2>&1
	sed -i '/gaussdb/d' /etc/exports >> /dev/null 2>&1
    if [ -d /home ];then
        cd /home
		if [ -d topus ];then
            rm -rf topus >> /dev/null 2>&1
        fi
        if [ -d gaussdba ]; then
            rm -rf gaussdba >> /dev/null 2>&1
        fi
    fi
    
    if [ -d /opt ];then
        cd /opt
	    if [ -d topus ]; then
            rm -rf topus >> /dev/null 2>&1
        fi
        if [ -d gaussdb ]; then
            rm -rf gaussdb >> /dev/null 2>&1
        fi
    fi
    groupdel topus >> /dev/null 2>&1
    return $RESULT_OK
}

# **************************************************************************** #
# Function    : uninstall
# Description : uninstall api from the OS
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function uninstall()
{
    local logfile=$LOG_SYSTEM_PATH/gaussdb_uninstall.log
    echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] uninstall API-MGT started" > $logfile    

    print_title "Uninstall GAUSSDB"
	sed -i '/ulimit -HSn 240000/d' /etc/profile 
    uninstall_gaussdb
    if [ $? -ne 0 ]; then
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] uninstall gaussdb failed" >> $logfile
        return $RESULT_ERROR
    else
        echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] uninstall gaussdb success" >> $logfile
    fi    
    
    uninstall_java
    if [ $? -ne 0 ]; then
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] uninstall java failed" >> $logfile
        return $RESULT_ERROR
    else
        echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] uninstall java success" >> $logfile
    fi
    
    uninstall_user
    if [ $? -ne 0 ]; then
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] remove user failed" >> $logfile
        return $RESULT_ERROR
    else
        echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] remove user success" >> $logfile
    fi
    
    uninstall_check
    if [ $? -ne 0 ]; then
        echo -e "[`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] uninstall check failed" >> $logfile
        return $RESULT_ERROR
    else
        echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] uninstall check success" >> $logfile
    fi
    
    rm -f /tmp/.s.PGSQL.${database_port} >> $logfile 2>&1
    rm -f /tmp/.s.PGSQL.${database_port}.lock >> $logfile 2>&1
    
    print_title "Uninstall GAUSSDB Successful"
    echo -e "[`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] Uninstall GAUSSDB Successful" >> $logfile
    return $RESULT_OK
}

# //////////////////////////////////////////////////////////////////////////// #
#                                                                              #
#                                Start Apimgt                                  #
#                                                                              #
# //////////////////////////////////////////////////////////////////////////// #

# **************************************************************************** #
# Function    : start_gaussdb
# Description : start_gaussdb
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function start_gaussdb()
{
    if [ ! "$active_mode" = "stand-alone" ];then
        $ROOTPATH/scripts/database/gaussdb.sh start -M $active_mode $verbose
    else
        $ROOTPATH/scripts/database/gaussdb.sh start $verbose
    fi
    result=$?
    if [ $result -eq $BUILD_ERROR ]; then
        print_log_to_screen "gaussdb build" "$fTAG: please build gaussdb by youself"
    fi
    if [ $result -ne 0 ]; then
        return $RESULT_ERROR
    fi    
    return $RESULT_OK
}

function install_check()
{
    ret=$RESULT_OK
    su - gaussdba -c "gs_ctl -V" >> /dev/null 2>&1
    if [ $? -eq 0 ]; then
        ret=$RESULT_ERROR
    fi
    return $ret;
}

# **************************************************************************** #
# Function    : startserver
# Description : start api server
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function startserver()
{
    # The default system log for shell 
    LOG_SYSTEM_PATH=/opt/gaussdb/log/
    
    local logfile=$LOG_SYSTEM_PATH/gaussdb_start.log
    su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] starting API-MGT. >> $logfile 2>&1"            
    
    print_title " Start GAUSSDB"
    install_check
    if [ $? -eq 0 ]; then
        print_log_to_screen "start system" "$FTAG : system is not installed!"
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] system is not installed. >> $logfile 2>&1"        
        return $RESULT_ERROR
    fi
    stopcheck >> /dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_log_to_screen "start system" "$FTAG : system is already started!"
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] system is already started. >> $logfile 2>&1"               
        return $RESULT_REOPRATION
    fi
	if [ "$active_mode" != "stand-alone" ];then
            active_mode="standby"
	fi
    start_gaussdb
    if [ $? -ne 0 ]; then
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] start gaussdb failed. >> $logfile 2>&1"        
        return $RESULT_ERROR
    else
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] start gaussdb success. >> $logfile 2>&1"         
    fi
  print_title " Start Gaussdb Successful"
}

function stopforce()
{
    ret=$RESULT_OK   
    su - gaussdba -c "gs_ctl query" >> /dev/null 2>&1
    if [ 0 -eq $? ]; then
    su - gaussdba -c "gs_ctl stop" >/dev/null 2>&1
    fi
    return $ret
}

function stopcheck()
{
    ret=$RESULT_OK   
    su - gaussdba -c "gs_ctl query" >> /dev/null 2>&1
    if [ 0 -eq $? ]; then
        print_log_to_screen "stop gaussdb" "$FTAG"
        ret=$RESULT_ERROR
    fi
    return $ret
}

# **************************************************************************** #
# Function    : stopserver
# Description : stopserver
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : 
# **************************************************************************** #

function stopserver()
{   
    # The default system log for shell 
    LOG_SYSTEM_PATH=/opt/gaussdb/log/
    
    local logfile=$LOG_SYSTEM_PATH/gaussdb_stop.log
    su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] stopping API-MGT. >> $logfile 2>&1"
    
    print_title "Stop GAUSSDB"
    install_check
    if [ $? -eq 0 ]; then
        print_log_to_screen "stop system" "$FTAG : system is not installed!"
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM]  API-MGT is not installed. >> $logfile 2>&1"
        return $RESULT_ERROR
    fi
    stopcheck >> /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_log_to_screen "stop system" "$FTAG : system is already stopped!"
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM]  API-MGT is already stopped. >> $logfile 2>&1"
        return $RESULT_REOPRATION
    fi

    $ROOTPATH/scripts/database/gaussdb.sh stop $verbose
    if [ $? -ne 0 ]; then
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] stop gaussdb failed. >> $logfile 2>&1"
        return $RESULT_ERROR
    else
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] stop gaussdb success. >> $logfile 2>&1"         
    fi
    
    stopcheck >> /dev/null 2>&1
    if [ $? -ne 0 ]; then
        stopforce >> /dev/null 2>&1
    fi
    stopcheck
    if [ $? -ne 0 ]; then
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] stop check failed. >> $logfile 2>&1"
        return $RESULT_ERROR
    else
        su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] stop check success. >> $logfile 2>&1"         
    fi
    
    print_title "Stop GAUSSDB Successful"
    su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] Stop GAUSSDB Successful. >> $logfile 2>&1"      
    return $RESULT_OK
}


# //////////////////////////////////////////////////////////////////////////// #
#                                                                              #
#                           Configuration Check                                #
#                                                                              #
# //////////////////////////////////////////////////////////////////////////// #

# **************************************************************************** #
# Function    : check_mode_config
# Description : check mode configuration
# Parameter   : none
# Return      : mode_config_error
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
# **************************************************************************** #

function check_mode_config()
{
    local mode_config_error=0
    
    if [ -z "$active_mode" ]; then
        mode_config_error=1
        echo -e "$FTAG active_mode must be setted in config.ini."
        return $mode_config_error
    fi
    
    if [ "$active_mode" != "primary" ] \
    && [ "$active_mode" != "standby" ] \
    && [ "$active_mode" != "stand-alone" ]; then
        mode_config_error=1
        echo -e "$FTAG active_mode can be setted as primary, standby and stand-alone only."
    fi
    
    return $mode_config_error
}
# **************************************************************************** #
# Function    : check_default_value
# Description : check mode configuration
# Parameter   : none
# Return      : mode_config_error
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
# **************************************************************************** #

function check_default_value()
{
    local mode_config_error=0
    if [ -z "$database_port" ]; then
        mode_config_error=1
        echo -e "$FTAG database_port Can't be empty"
    fi
    if [ -z "$database_ip" ]; then
        mode_config_error=1
        echo -e "$FTAG database_ip Can't be empty"
    fi
    if [ -z "$database_data_path" ]; then
        mode_config_error=1
        echo -e "$FTAG database_data_path Can't be empty"
    fi
	
    return $mode_config_error
}

# **************************************************************************** #
# Function    : check_gateway_config
# Description : check local_gateway_ip at all mode
# Parameter   : none
# Return      : gateway_config_error
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
# **************************************************************************** #

function check_gateway_config()
{
    local gateway_config_error=0

    if [ "$active_mode" != "stand-alone" ]; then
        if [ -z "$local_gateway_ip" ]; then
            gateway_config_error=1
            echo -e "$FTAG local_gateway_ip must be setted at $active_mode mode."
        fi
        if [ -z "$remote_gateway_ip" ]; then
            gateway_config_error=1
            echo -e "$FTAG remote_gateway_ip must be setted at $active_mode mode."
        fi
        if [ "$local_gateway_ip" = "$remote_gateway_ip" ]; then
            gateway_config_error=1
            echo -e "$FTAG local_gateway_ip and remote_gateway_ip can't be the same."
        fi   
    fi
    
    return $gateway_config_error 
}
# **************************************************************************** #
# Function    : check_heartbeat_config
# Description : check heartbeat at non-stand-alone mode 
# Parameter   : none
# Return      : sync_config_error
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
# **************************************************************************** #

function check_heartbeat_config()
{
    local sync_config_error=0

    if [ -z "$sync_localhost_ip1" ]; then
        sync_config_error=1
        echo -e "$FTAG sync_localhost_ip1 must be setted at $active_mode mode."
    fi
    if [ -z "$sync_remotehost_ip1" ]; then
        sync_config_error=1
        echo -e "$FTAG sync_remotehost_ip1 must be setted at $active_mode mode."
    fi
    if [ "$sync_localhost_ip1" = "$sync_remotehost_ip1" ]; then
        sync_config_error=1
        echo -e "$FTAG sync_localhost_ip1 and sync_remotehost_ip1 can't be the same."
    fi
    
    if [ -z "$sync_localhost_ip2" ]; then
        sync_config_error=1
        echo -e "$FTAG sync_localhost_ip2 shoud must be setted at $active_mode mode."
    fi
    if [ -z "$sync_remotehost_ip2" ]; then
        sync_config_error=1
        echo -e "$FTAG sync_remotehost_ip2 shoud must be setted at $active_mode mode."
    fi
    if [ "$sync_localhost_ip2" = "$sync_remotehost_ip2" ]; then
        sync_config_error=1
        echo -e "$FTAG sync_localhost_ip2 and sync_remotehost_ip2 can't be the same."
    fi  
    return $sync_config_error
}

# **************************************************************************** #
# Function    : check_vip_and_eth_config
# Description : check vip and eth at non-stand-alone mode 
# Parameter   : none
# Return      : vip_check_error
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974 
# **************************************************************************** #

function check_vip_and_eth_config()
{
    local vip_check_error=0
    
    if [ -z "$dispatch_vip" ]; then
        vip_check_error=1
        echo -e "$FTAG dispatch_vip must be setted at $active_mode mode."
    fi
    if [ -z "$dispatch_phy_ip" ]; then
        vip_check_error=1
        echo -e "$FTAG dispatch_phy_ip must be setted at $active_mode mode."
    fi
    
    if [ -z "$dispatch_remote_phy_ip" ]; then
        vip_check_error=1
        echo -e "$FTAG dispatch_remote_phy_ip must be setted at $active_mode mode."
    fi
    return $vip_check_error
}

# **************************************************************************** #
# Function    : check_interface_validity
# Description : check the validity of interface parameter, which is called 
#               by function check_parameter
# Parameter   : $1 - suffix of interface parameter
# Return      : none
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
# **************************************************************************** #

function check_interface_validity()
{
    if [[ ${1:0:3} != "eth" ]]; then
        print_log_to_screen "\"$1\" is not a valid interface" "PTAG"
        exit $PARAMETERS_ERR
    else
        subfix=${1:3}
        
        if [ ${#subfix} -eq 0 ]; then
            print_log_to_screen "\"$1\" is not a valid interface" "PTAG"
            exit $PARAMETERS_ERR;
        fi
        
        if [[ ! $subfix =~ ^[0-9]*[0-9]$ ]]; then
            print_log_to_screen "\"$1\" is not a valid interface" "PTAG"  
            exit $PARAMETERS_ERR;
        fi
        
        if [ ${#subfix} -ne 1 -a ${subfix:0:1} = "0" ]; then
            print_log_to_screen "\"$1\" is not a valid interface" "PTAG"   
            exit $PARAMETERS_ERR;
        fi        
    fi
}

# **************************************************************************** #
# Function    : check_vipaddress_validity
# Description : check the validity of virtual_ipaddress parameter, which is 
#               called by function check_parameter
# Parameter   : $1 suffix of priority parameter
# Return      : none
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974 
# **************************************************************************** #

function check_vipaddress_validity()
{
    # ip address must own 4 column, and echo column must be a digit
    echo $1|grep "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}$" > /dev/null;
    if [ $? -ne 0 ]; then
        print_log_to_screen "\"$1\" is not a valid ip address" "PTAG"   
        exit $PARAMETERS_ERR
    fi
    
    # divided the ip address by character "." 
    ipaddr=$1
    a=`echo $ipaddr|awk -F . '{print $1}'`
    b=`echo $ipaddr|awk -F . '{print $2}'`
    c=`echo $ipaddr|awk -F . '{print $3}'`
    d=`echo $ipaddr|awk -F . '{print $4}'`
    
    # echo number must less than 255 and great than 0
    for num in $a $b $c $d; do
        if [ $num -gt 255 ] || [ $num -lt 0 ]; then
            print_log_to_screen "\"$1\" is not a valid ip address" "PTAG"  
            exit $PARAMETERS_ERR
        fi
    done
}

# **************************************************************************** #
# Function    : check_config
# Description : check system config
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : Foundation PaaS API-MANAGEMENT V100R001C00
# Others      : c00284974
# **************************************************************************** #

function check_config()
{
    local config_error=0
    
    # check mode configuration, return when error
    check_mode_config
    if [ $? -ne 0 ]; then
        config_error=1
        return $config_error
    fi
	check_default_value
    if [ $? -ne 0 ]; then
        config_error=1
        return $config_error
    fi
    return $config_error
}

# //////////////////////////////////////////////////////////////////////////// #
#                                                                              #
#                              Main Operation                                  #
#                                                                              #
# //////////////////////////////////////////////////////////////////////////// #

# **************************************************************************** #
# Function    : check_before_operation
# Description : do some check before operation
# Parameter   : none
# Return      : none
# **************************************************************************** #

function check_before_operation()
{
    if [ $USERID -ne 0 ]; then
        echo -e "Only the root user can operate      \033[31;49;1m[FATAL]\033[0m"
        exit $?
    fi

    if [ ! -f $ROOTPATH/configure/config.ini ]; then
        echo -e "config.ini is missing               \033[31;49;1m[FATAL]\033[0m"  
        exit $RESULT_ERROR
    fi


        check_config
        if [ $? -ne 0 ]; then
            exit $RESULT_ERROR
        fi

    chmod u+x $ROOTPATH/scripts/*/*.sh -R
    chmod o-rwx $ROOTPATH/configure -R
}

# **************************************************************************** #
# Function    : restart
# Description : print version information
# Parameter   : none
# Return      : none
# **************************************************************************** #

function restart()
{
    stopcheck >> /dev/null 2>&1
    if [ $? -ne 0 ]; then
        stopserver
        result=$?
        if [ $result -ne 0 ]; then
            return $result 
        fi
    fi
        startserver
        result=$?

    if [ $result -eq 0 ]; then
        return $RESULT_OK
    else
        return $result 
    fi
}
# **************************************************************************** #
# Function    : print_version
# Description : print version information
# Parameter   : none
# Return      : none
# **************************************************************************** #

function print_version()
{
    $ROOTPATH/scripts/database/gaussdb.sh -V
}
# **************************************************************************** #
# Function    : clean_passwd_in_config
# Description : set all password to null in propeties.xml under install package dir
# Parameter   : none
# Return      : none
# **************************************************************************** #
function clean_passwd_in_config()
{
    xml_file="$ROOTPATH/configure/properties.xml"
    sed -i 's/password">.*</password"></g' $xml_file >> /dev/null 2>&1
}
# **************************************************************************** #
# Since: Foundation PaaS API-MANAGEMENT V100R001C00
# **************************************************************************** #

# import configurations from config.ini
source $ROOTPATH/configure/config.ini

# do some check before operation
check_before_operation

# process input parameters
while [ "$1" != "" ]; do
    case "$1" in
        "install" | "uninstall" | "start" | "stop" | "status" | "restart" )
            operate="$1"
            ;;
        "-v" | "--verbose" )
            verbose="-v"
            ;;        
        "-V" | "--version" )
            print_version
            exit $RESULT_OK
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
        result=$?
       if [ $result -eq 0 ]; then		
            exit $RESULT_OK
       else
        uninstall
            exit $result 
       fi
        ;;
    "uninstall" )
        uninstall
        result=$?
        if [ $result -eq 0 ]; then
            exit $RESULT_OK
        else
            exit $result 
        fi
        ;;
    "start" )
            startserver
            result=$?
        if [ $result -eq 0 ]; then
            exit $RESULT_OK
        else
            exit $result 
        fi	
        ;;
    "stop" )
            stopserver
            result=$?
        if [ $result -eq 0 ]; then
            exit $RESULT_OK
        else
            exit $result 
        fi
        ;;
    "restart" )
        restart
        result=$?
        if [ $result -eq 0 ]; then
            exit $RESULT_OK
        else
            exit $result 
        fi
        ;;
    "status" )
        sh $ROOTPATH/scripts/topus/topus_status.sh -d
        exit
        ;;
    * ) 
        echo -e "parameter invalid. use parameter --help to get help."    
        exit $PARAMETER_ERROR
        ;;
esac
