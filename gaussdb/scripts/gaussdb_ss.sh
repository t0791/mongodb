#!/bin/bash

# A UTILITY to start/stop a GaussDB server. This script must be run by gaussdba.
#
# Created on: 2014-08-15
#     Author: l90005887

server_mode=""
operate=""
UTILITY="$0"
UTILITY_NAME=${UTILITY##*/}
verbose="false"
RESULT_OK=0
RESULT_ERROR=1
PARAMETER_ERROR=2
BUILD_ERROR=6
ROOTPATH=$(cd "$(dirname "$0")"; pwd)
gs_data_path="/data/gaussdb/data"
JAVA_PATH="/opt/gaussdb/jdk/bin"
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

# **************************************************************************** #
# Function Name: print_help
# Description: show the help message of this script
# Parameter: none
# Return: none
# **************************************************************************** #
function print_help()
{
cat <<!INFORMATION!
    $UTILITY_NAME is a UTILITY to start/stop a GaussDB server. It must be run by gaussdba.
    
Usage:
    $UTILITY_NAME start [-v] [-M SERVERMODE]
    $UTILITY_NAME stop  [-v]
    $UTILITY_NAME [options]

Common options:
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

function state_gaussdb()
{
    state=$(nohup su - gaussdba -c "gs_ctl query -L" 2>&1)
    echo "$state" 
}

# **************************************************************************** #
# Function Name: start_gaussdb
# Description: start gaussdb server
# Parameter: none
# Return: 0: successful; other: fail
# **************************************************************************** #
function start_gaussdb()
{
    LOG_SYSTEM_PATH=/opt/gaussdb/log/
    
    logfile=$LOG_SYSTEM_PATH/gaussdb_start.log
    su - gaussdba -c "echo -e [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] starting gaussdb >> $logfile  2>&1"
    #check the service status
    su - gaussdba -c "gs_ctl status -L" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        if [ "standby" = "$server_mode" ]; then
            if [ -f $gs_data_path/build_completed.start ]; then
                su - gaussdba -c "gs_ctl build"  >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                     su - gaussdba -c "echo -e [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] starting gaussdb failed and build failed >> $logfile  2>&1"
                    
                    return $BUILD_ERROR
                fi
            fi
        fi
        if [ -z "$server_mode" ]
        then
            su - gaussdba -c "gs_ctl start" >/dev/null 2>&1
        else
            su - gaussdba -c "gs_ctl start -M $server_mode"
        fi
        
        
        #check the service status
        su - gaussdba -c "gs_ctl status -L" >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
            return $RESULT_ERROR
        else
            return $RESULT_OK
        fi
    else
        print_verbose "GaussDB server has started."
        
        return $RESULT_OK
    fi
}

# **************************************************************************** #
# Function Name: stop_gaussdb
# Description: stop gaussdb server
# Parameter: none
# Return: 0: successful; other: fail
# **************************************************************************** #
function stop_gaussdb()
{
    #check the service status
    su - gaussdba -c "gs_ctl status -L" >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        su - gaussdba -c "gs_ctl stop" >/dev/null 2>&1
        kill -9 $(cat /opt/gaussdb/gaussdb/data/postmaster.pid | head -1)>/dev/null 2>&1
        #check the service status
        su - gaussdba -c "gs_ctl status -L" >/dev/null 2>&1
        if [ $? -eq 3 ]
        then
            return $RESULT_OK
        else
            return $RESULT_ERROR
        fi
    else
        print_verbose "GaussDB server has stoped."
		# Stop file sync
		ps -A | grep rsync.sh >> /dev/null 2>&1
		if [ 0 -eq $? ]; then
			pkill -9 rsync.sh >> /dev/null 2>&1
			if [ $? -ne 0 ]; then
				su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] stop rsync failed. >> $logfile 2>&1"
			else
				su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] stop rsync success. >> $logfile 2>&1"             
			fi 
		fi   
        return $RESULT_OK
    fi
}
function add_primarytask()
{        
    if [ ! -d /backup/topus/statistics ]; then
		mkdir -p /backup/topus/statistics
	fi
	crontab -l 1> $$.bak 2>> /dev/null
	start_jar=$(ls /opt/gaussdb/scripts/statmgt/ | grep com.huawei.am.igt.statmgt) 1>> /dev/null
	sed -i '/com.huawei.am.igt.statmgt/d' $$.bak
	echo "1 0 * * * cd /opt/gaussdb/scripts/statmgt/ && $JAVA_PATH/java -jar $start_jar &> /dev/null"  >> $$.bak  
	crontab $$.bak
	if [ $? -ne 0 ]; then
        print_log_to_screen "start timer task" "$FTAG : add primarytask failed"
		rm -f $$.bak
        return $RESULT_ERROR
    fi
    rm -f $$.bak
	return $RESULT_OK
}

function add_gaussdba_task()
{
    #begin to add task of clean gaussdb log        
    crontab -l -u gaussdba 1> $$.bak 2>> /dev/null
    sed -i '/cleandblog.sh/d' $$.bak
	sed -i '/cleansyslog.sh/d' $$.bak
    # Add clean old db log task by every day at 00:10
    echo "10 0 * * * /opt/gaussdb/scripts/gaussdb/cleandblog.sh &> /dev/null" >> $$.bak
	echo "10 0 * * * /opt/gaussdb/scripts/gaussdb/cleansyslog.sh &> /dev/null" >> $$.bak
    crontab -u gaussdba $$.bak
    if [ $? -ne 0 ]; then
        print_log_to_screen "start timer task" "$FTAG : add gaussdba task failed"
		rm -f $$.bak
        return $RESULT_ERROR
    fi    
    rm -f $$.bak
    #end of add task of clean gaussdb log 
    
    # distinguish the system type
    if [ -f /etc/redhat-release ]; then
        local servername=crond
    else
        local servername=cron
    fi
    
    ps -A | grep $servername >> /dev/null 2>&1
    if [ 0 -eq $? ]; then
        print_log_to_screen "start timer task" "$STAG"
        return $RESULT_OK
    else    
        service $servername start 1> /dev/null
        if [ $? -ne 0 ]; then
            print_log_to_screen "start timer task" "$FTAG : start task failed"
            return $RESULT_ERROR
        fi
    fi
}

function add_task()
{
    #begin to add task of clean gaussdb log        
    crontab -l 1> $$.bak 2>> /dev/null
    sed -i '/check_rsync.sh/d' $$.bak
    # Add clean old db log task by every day at 00:10
    echo "*/1 * * * * sh /opt/gaussdb/scripts/common/check_rsync.sh &> /dev/null" >> $$.bak
    crontab $$.bak
    if [ $? -ne 0 ]; then
        print_log_to_screen "start timer task" "$FTAG : add task failed"
		rm -f $$.bak
        return $RESULT_ERROR
    fi    
    rm -f $$.bak
}

function delete_task()
{
	crontab -l -u gaussdba 1> $$.bak 2>> /dev/null
	sed -i '/cleandblog.sh/d' $$.bak
	sed -i '/cleansyslog.sh/d' $$.bak
	crontab -u gaussdba $$.bak
	if [ $? -ne 0 ]; then
        print_log_to_screen "start timer task" "$FTAG : delete gaussdba task failed"
		rm -f $$.bak
    fi    
	rm -f $$.bak 	
	crontab -l 1> $$.bak 2>> /dev/null
	sed -i '/com.huawei.am.igt.statmgt/d' $$.bak
    sed -i '/check_rsync.sh/d' $$.bak
	crontab $$.bak
    if [ $? -ne 0 ]; then
        print_log_to_screen "start timer task" "$FTAG : delete task failed"
		rm -f $$.bak
    fi    
	rm -f $$.bak 
}

if [ ! -f $ROOTPATH/../../configure/config.ini ]; then
echo -e "config.ini is missing"  
exit $RESULT_ERROR
fi
source $ROOTPATH/../../configure/config.ini
if [ "$database_data_path" != "" ]; then
    gs_data_path="$database_data_path/data"
fi
#get parameters
while [ "$1" != "" ]
do
    case "$1" in
        "start" | "stop" | "state" )
            operate="$1"
            ;;
        "-v" | "--verbose" )
            verbose="true"
            ;;
        "-V" | "--version" )
            su - gaussdba -c "gs_ctl -V"
            
            exit $RESULT_OK
            ;;
        "-M" )
            #get parameter for -M
            if [ -n "$2" ]
            then
                if [ "$2" = "primary" ] || [ "$2" = "standby" ] || [ "$2" = "pending" ]
                then
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
            echo -e "parameter " $1 " invalid. use patameter --help to get help."
            
            exit $PARAMETER_ERROR
            ;;
    esac

    shift
done

if [ -z "$operate" ]
then
    echo -e "parameter error. use patameter --help to get help."
    
    exit $PARAMETER_ERROR
fi

case "$operate" in
    "start" )
        start_gaussdb >/dev/null 2>&1
        result=$?
        if [ $result -eq 0 ]; then
			  if [ "$server_mode" = "primary" ]; then
		        add_primarytask
		        if [ $? -ne 0 ]; then
                    su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] add primarytask failed. >> $logfile 2>&1"
                else
					su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] add primarytask success. >> $logfile 2>&1"
                fi
	          fi
		        add_gaussdba_task
			    if [ $? -ne 0 ]; then
                    su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] add gaussdba task failed. >> $logfile 2>&1"
                else
					su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] add gaussdba task success. >> $logfile 2>&1"
                fi
				add_task
			    if [ $? -ne 0 ]; then
                    su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [ERROR] [root] [SYSTEM] add task failed. >> $logfile 2>&1"
                else
					su - gaussdba -c "echo [`date +%Y-%m-%d' '%T`] [INFO] [root] [SYSTEM] add task success. >> $logfile 2>&1"
                fi
            print_log_to_screen "start gaussdb" "$STAG"
            exit $result
        else
            print_log_to_screen "start gaussdb" "$FTAG"
            exit $result
        fi
        ;;
    "stop" )
        stop_gaussdb >/dev/null 2>&1
        if [ $? -eq 0 ]
        then
			delete_task
            print_log_to_screen "stop gaussdb" "$STAG"
            exit $RESULT_OK
        else
            print_log_to_screen "stop gaussdb" "$FTAG"
            exit $RESULT_ERROR
        fi
        ;;
    "state" )
        state_gaussdb
        ;;
    * )
        echo -e "parameter invalid. use patameter --help to get help."
            
        exit $PARAMETER_ERROR
        ;;
esac
