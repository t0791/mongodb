#!/bin/bash

# A UTILITY to install/uninstall a GaussDB or start/stop a GaussDB server. This script
# whill invoke gaussdb_ss.sh at the same directory. This script must be run by root.
#
# Created on: 2014-08-12
#     Author: l90005887

#example: GaussDB-V200R001C00SPC010B160-RedHatEnterpriseServer6.4-64bit.tar.gz
package_path="./"
server_mode=""
operate=""
UTILITY="$0"
UTILITY_NAME=${UTILITY##*/}
verbose="false"
ROOTPATH=$(cd "$(dirname "$0")"; pwd)
gs_data_path="/data/gaussdb/data"
gs_app_path="/opt/gaussdb/app"
crypto_jar=$ROOTPATH/../../install/com.huawei.am.igt.pwdjobexecutor-1.0.0.jar
AMUSER="gaussdb"
JDK_VERSION=jdk
java_path=/opt/$AMUSER/$JDK_VERSION/bin

RESULT_OK=0
RESULT_ERROR=1
PARAMETER_ERROR=2
profilename=.bash_profile
# colourful status tag for display
FTAG="\033[31;49;1mFAILURE\033[0m"
STAG="\033[32;49;1mSUCCESS\033[0m"
RTAG="\033[33;49;1mRunning\033[0m"

sTAG="\033[36;49msuccess\033[0m"
fTAG="\033[35;49mfailure\033[0m"

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

function set_env_command()
{
    command_pre="[[ ! \$LD_LIBRARY_PATH =~ \"$gs_app_path/lib\" ]]"
    command_sub="sed -i '\$a export LD_LIBRARY_PATH=\"$gs_app_path/lib\":\$LD_LIBRARY_PATH' ~/.bashrc"
    su - gaussdba -c "${command_pre} && ${command_sub}"
    command_pre="[[ ! \$PATH =~ \"$gs_app_path/bin\" ]]"
    command_sub="sed -i '\$a export PATH=\"$gs_app_path/bin\":\$PATH' ~/${profilename}"
    su - gaussdba -c "${command_pre} && ${command_sub}"
    local ip1=`echo $dispatch_vip |awk -F. '{print $1}'`
	local ip2=`echo $dispatch_vip |awk -F. '{print $2}'`
    # change unix_socket_permissions = 0777 to 0770
    su - gaussdba -c "sed -i \"s/#unix_socket_permissions = 0777/unix_socket_permissions = 0770/g\" $gs_data_path/postgresql.conf"
	chmod 700 $gs_app_path
    chmod 700 $gs_app_path/archive
    su - gaussdba -c "sed -i \"s/#listen_addresses = 'localhost'/listen_addresses = '${database_ip},localhost'/g\" $gs_data_path/postgresql.conf"
    su - gaussdba -c "sed -i \"s/32/0/g\" $gs_data_path/pg_hba.conf"
    su - gaussdba -c "sed -i \"s/128/0/g\" $gs_data_path/pg_hba.conf"
}

function del_env_command()
{
    match_str="\"$gs_app_path/lib\""
    result=$(su - gaussdba -c "grep -n $match_str ~/.bashrc | head -1 | cut -d \":\" -f 1")
    if [ -z $result ]; then
        return
    else
        su - gaussdba -c "sed -i '${result}d' ~/.bashrc"
    fi

    match_str="\"$gs_app_path/bin\""
    result=$(su - gaussdba -c "grep -n $match_str ~/${profilename} | head -1 | cut -d \":\" -f 1")
    if [ -n $result ]; then
        return
    else
        su - gaussdba -c "sed -i '${result}d' ~/${profilename}"
    fi
}

function set_connect_command()
{
    su - gaussdba -c "gs_ctl start"
    su - gaussdba -c "gs_guc reload -c listen_addresses=\"'*'\""
}

unset_env_command=""

# **************************************************************************** #
# Function Name: print_help
# Description: show the help message of this script
# Parameter: none
# Return: none
# **************************************************************************** #
function print_help()
{
cat <<!INFORMATION!
    $UTILITY_NAME is a UTILITY to install/uninstall a GaussDB or start/stop a GaussDB server.
It must be run by root.

Usage:
    $UTILITY_NAME install   [-v] [-P PACKAGE]
    $UTILITY_NAME uninstall [-v]
    $UTILITY_NAME start     [-v] [-M SERVERMODE]
    $UTILITY_NAME stop      [-v]
    $UTILITY_NAME [options]

Common options:
    -P               the path of the installation package.
    -M               the database start as the appointed mode.
    -v, --verbose    more verbose marginal on marginal errors.
    -V, --version    output version information, then exit.
    -?, --help       show this help info, then exit.

SERVERMODE are:
    primary        database system starts as a primary server, send xlog to standby server.
    standby        database system starts as a standby server, receive xlog from primary server.
    pending        database system starts as a pending server, wait for promoting to primary or 
                   demoting to standby.

    Only used in start command.
!INFORMATION!
}

# **************************************************************************** #
# Function Name: print_verbose
# Description: show the information if verbose is set
# Parameter: information
# Return: none
# **************************************************************************** #
function print_verbose()
{
    information="$1"
    if [ -n "$information" ] && [ "$verbose" = "true" ]; then
        echo -e "$information"
    fi
}

# **************************************************************************** #
# Function Name: install_gaussdb
# Description: install GaussDB to the OS
# Parameter: the path of GaussDB package
# Return: 0: successful; other: fail
# **************************************************************************** #

function install_gaussdb()
{
    print_log_to_screen "check gaussdb package ..."
    if [ ! -d "$package_path" ]; then
        echo -e "$fTAG : package missing"
        return $PARAMETER_ERROR
    fi
    echo -e "$sTAG"
    
    print_log_to_screen "uncompress gaussdb package ..."
    tar -xzvf "$package_path""$gaussdb_package" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "$fTAG : tar failed"
        return $RESULT_ERROR
    fi
    echo -e "$sTAG"
    if [ ! -d "$gs_app_path" ]; then
        mkdir -p "$gs_app_path"
        chown -R gaussdba:dbgrp /opt/gaussdb
        chmod u+x /opt/gaussdb
    fi
    if [ ! -d "$database_data_path" ] && [ "$database_data_path" != "" ]; then
        mkdir -p "$database_data_path"
        chown -R gaussdba:dbgrp $database_data_path
        chmod u+rx $database_data_path
    fi
	mkdir -p "/data/gaussdb"
	chown -R gaussdba:dbgrp /data/gaussdb
	chmod 755 -R /data
    print_log_to_screen "install gaussdb package ..."
    dbUserGaussdbaPassword=$(sh $ROOTPATH/../../install/get_password.sh -a DB.user.gaussdba.password)
    echo "#!/bin/bash" > $ROOTPATH/temp.sh
    chmod u+x $ROOTPATH/temp.sh
    echo "export gs_app_path=$gs_app_path" >> $ROOTPATH/temp.sh
    echo "export gs_data_path=$gs_data_path" >> $ROOTPATH/temp.sh
    echo "export database_port=$database_port" >> $ROOTPATH/temp.sh
    if [ -z "$server_mode" ]; then
        result=`$java_path/java -jar $crypto_jar "dbUserGaussdbaPassword=$dbUserGaussdbaPassword" $ROOTPATH/gaussdb_primary_cmd.sh $ROOTPATH/../../install/crypto 2>> /dev/null`
    else
        echo "export sync_localhost_ip1=$sync_localhost_ip1" >> $ROOTPATH/temp.sh
        echo "export sync_localhost_port1=$sync_localhost_port1" >> $ROOTPATH/temp.sh
        echo "export sync_remotehost_ip1=$sync_remotehost_ip1" >> $ROOTPATH/temp.sh
        echo "export sync_remotehost_port1=$sync_remotehost_port1" >> $ROOTPATH/temp.sh
        echo "export sync_localhost_ip2=$sync_localhost_ip2" >> $ROOTPATH/temp.sh
        echo "export sync_localhost_port2=$sync_localhost_port2" >> $ROOTPATH/temp.sh
        echo "export sync_remotehost_ip2=$sync_remotehost_ip2" >> $ROOTPATH/temp.sh
        echo "export sync_remotehost_port2=$sync_remotehost_port2" >> $ROOTPATH/temp.sh

        result=`$java_path/java -jar $crypto_jar "dbUserGaussdbaPassword=$dbUserGaussdbaPassword" $ROOTPATH/gaussdb_standby_cmd.sh $ROOTPATH/../../install/crypto 2>> /dev/null`
    fi
    if [ $? -ne 0 ]; then
        echo -e "$fTAG : $result"
        return $RESULT_ERROR
    fi
    echo -e "$sTAG"
    
}

# **************************************************************************** #
# Function Name: uninstall_gaussdb
# Description: uninstall GaussDB from the OS
# Parameter: none
# Return: 0: successful; other: fail
# **************************************************************************** #
function uninstall_gaussdb()
{
    # uninstall GaussDB

    if [ -f /etc/redhat-release ]; then
        bin_path=$gs_app_path/gaussdb/bin
    else
        bin_path=$gs_app_path/bin
    fi

    if [ -d $bin_path ]; then
        output=$(python $bin_path/uninstall.py -U gaussdba -F -D $gs_data_path >> /dev/null 2>&1)
        result=$?
        
        if [ $result -ne 0 ]; then
            print_log_to_screen "uninstall gaussdb" "$FTAG : uninstall failed"
            return $RESULT_ERROR
        fi
    else
        print_log_to_screen "uninstall gaussdb" "$FTAG : /gaussdb/bin missing"
        return $PARAMETER_ERROR
    fi
    
    return $RESULT_OK
}


if [ ! -f $ROOTPATH/../../configure/config.ini ]; then
echo -e "config.ini is missing"  
exit $RESULT_ERROR
fi
source $ROOTPATH/../../configure/config.ini
if [ "$database_data_path" != "" ]; then
    gs_data_path="$database_data_path/data"
fi

if [ -f /etc/redhat-release ]; then
    profilename=.bash_profile
else
    profilename=.profile
fi

#get parameters
while [ "$1" != "" ]
do
    case "$1" in
        "install" | "uninstall" | "start" | "stop" )
            operate="$1"
            ;;
        "-v" | "--verbose" )
            verbose="true"
            ;;
        "-V" | "--version" )
            echo -e "
            GaussDB version         
            "
            su - gaussdba -c "gs_ctl -V"

            exit $RESULT_OK
            ;;
        "-P" )
            #get parameter for -P
            if [ -n "$2" ]; then
                if [ -f "$2" ]; then
                    package="$2"
                    gaussdb_package=${package##*/}
                    if [ -n "${package%%$gaussdb_package}" ]; then
                        package_path=${package%%$gaussdb_package}
                    fi

                    shift
                else
                    echo -e "parameter error for -P, it is not a file."

                    exit $PARAMETER_ERROR
                fi
            else
                echo -e "require more parameter for -P."

                exit $PARAMETER_ERROR
            fi
            ;;
        "-M" )
            #get parameter for -M
            if [ -n "$2" ]; then
                if [ "$2" = "primary" ] || [ "$2" = "standby" ] || [ "$2" = "pending" ]; then
                    server_mode="$2"

                    shift
                else
                    echo -e "parameter error for -M, use \"primary\" or \"standby\" or \"pending\"."

                    exit $PARAMETER_ERROR
                fi
            else
                echo -e "require more parameter for -M."

                exit $PARAMETER_ERROR
            fi
            ;;
        "-?" | "--help" )
            print_help

            exit $RESULT_OK
            ;;
        * )
            echo -e "parameter " $1 " invalid. use parameter --help to get help."

            exit $PARAMETER_ERROR
            ;;
    esac

    shift
done

if [ -z "$operate" ]; then
    echo -e "parameter error. use parameter --help to get help."

    exit $PARAMETER_ERROR
fi

case "$operate" in
    "install" )
        su - gaussdba -c "gs_ctl -V" >> /dev/null 2>&1
        if [ $? -ne 0 ]; then
            install_gaussdb
            if [ $? -ne 0 ]; then
                exit $RESULT_ERROR
            fi
        fi
        set_env_command  >> /dev/null 2>&1
        exit $RESULT_OK
        ;;
    "uninstall" )
        grep "^gaussdba:" /etc/passwd >> /dev/null 2>&1
        if [ $? -ne 0 ]; then
            print_log_to_screen "uninstall gaussdb" "$STAG"
            exit $RESULT_OK
        fi
        
        su - gaussdba -c "gs_ctl -V" >> /dev/null 2>&1
        if [ 0 -eq $? ]; then
            uninstall_gaussdb
            if [ $? -ne 0 ]; then
                exit $RESULT_ERROR
            fi
        fi
        del_env_command
        if [ "$database_data_path" != "" ]; then
            rm -rf $database_data_path >> /dev/null 2>&1
        else
            rm -rf /data/gaussdb >> /dev/null 2>&1
        fi
        print_log_to_screen "uninstall gaussdb" "$STAG"
        exit $RESULT_OK
        ;;
    "start" )
        command="/bin/bash $ROOTPATH/gaussdb_ss.sh start"

        if [ -n "$server_mode" ]; then
            command=$command" -M $server_mode"
        fi

        if [ "true" = "$verbose" ]; then
            command=$command" -v"
        fi
                
        $command

        exit $?
        ;;
    "stop" )
        command="/bin/bash $ROOTPATH/gaussdb_ss.sh stop"

        if [ "true" = "$verbose" ]; then
            command=$command" -v"
        fi
        
        $command

        exit $?
        ;;
    * )
        echo -e "parameter invalid. use parameter --help to get help."

        exit $PARAMETER_ERROR
        ;;
esac
