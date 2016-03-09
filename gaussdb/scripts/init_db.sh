#!/bin/bash

# Created on: 2014-08-14
#     Author: j00183313

UTILITY="$0"
UTILITY_NAME=${UTILITY#*/}
verbose="false"
ROOTPATH=$(cd "$(dirname "$0")"; pwd)
command_file=./.cmdfile_$$
RESULT_OK=0
RESULT_ERROR=1
PARAMETER_ERROR=2
dbname=
sql=
# **************************************************************************** #
# Function Name: print_help
# Description: show the help message of this script
# Parameter: none
# Return: none
# **************************************************************************** #
function print_help()
{
cat <<!INFORMATION!
$UTILITY_NAME is a UTILITY to initialize Database.
    
Usage:
    $UTILITY_NAME   [-v verbose] [-u DB_USERNAME] [-p DB_PASSWORD]

Common options:
    -v, --verbose          more verbose marginal on marginal errors.
    -?, --help             show this help info, then exit.
!INFORMATION!
}
function createcommand_file_c()
{
cat > $command_file << CMD_EOF
#!/usr/bin/expect -f
set timeout 50
spawn su - gaussdba -c "gsql -d $dbname -p $database_port -U apimgtdb -c \"$sql;\""
    expect {
        "*Invalid username/password*" {exit 3}
        "*could not connect to server*" {exit 2}
        "*assword for user*" {send "$userApimgtdbPassword\r";}
        "*ERROR*" {exit 1}
        eof {exit 0}
        timeout {exit 2}
    }
    expect {
        "*Invalid username/password*" {exit 3}
        "*already exists*" {exit 4}
        "*ERROR*" {exit 1}
        eof {exit 0}
        timeout {exit 2}
    }
exit 0
CMD_EOF
}
function createcommand_file_f()
{
cat > $command_file << CMD_EOF
#!/usr/bin/expect -f
set timeout 50
spawn su - gaussdba -c "gsql -d $dbname -p $database_port -U apimgtdb -f $sql;"
    expect {
        "*Invalid username/password*" {exit 3}
        "*could not connect to server*" {exit 2}
        "*assword for user*" {send "$userApimgtdbPassword\r";}
        "*ERROR*" {exit 1}
        eof {exit 0}
        timeout {exit 2}
    }
    expect {
        eof {exit 0}       
        timeout {exit 2}
    }
exit 0
CMD_EOF
}

function createcommand_dustman()
{
cat > $command_file << CMD_EOF
#!/usr/bin/expect -f
set timeout 50
spawn su - gaussdba -c "gsql -d $dbname -p $database_port -U apimgtdb -f $sql;"
    expect {
        "*Invalid username/password*" {exit 3}
        "*could not connect to server*" {exit 2}
        "*assword for user*" {send "$userApimgtdbPassword\r";}
        "*ERROR*" {exit 1}
        eof {exit 0}
        timeout {exit 2}
    }
    expect {
        "*CREATE FUNCTION*" {exit 0}
        eof {exit 0}        
        timeout {exit 2}
    }
exit 0
CMD_EOF
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
# Function    : revoke_from_public
# Description : REVOKE CREATE ON SCHEMA PUBLIC FROM public
# Parameter   : none
# Return      : 0 - success, 1 - failure
# Since       : 
# Others      : z00141106
# **************************************************************************** #
function revoke_from_public()
{
    dbname=$1
    sql="REVOKE CREATE ON SCHEMA PUBLIC FROM public"
    su - gaussdba -c "gsql -d $dbname -p $database_port -c \"$sql;\""
    ret=$?
    if [ $ret -eq 0 ]; then
        print_verbose "< REVOKE PUBLIC    > revoke public for $dbname     [\033[32;49;1m OK \033[0m]"
    else
        print_verbose "< REVOKE PUBLIC    > revoke public for $dbname     [\033[31;49;1m FAIL \033[0m]"
        exit $RESULT_ERROR 
    fi
}

# **********************  process start  ********************************* #

if [ ! -f $ROOTPATH/../../configure/config.ini ]; then
echo -e "config.ini is missing"  
exit $RESULT_ERROR
fi
source $ROOTPATH/../../configure/config.ini
#get parameters
while [ "$1" != "" ]
do
    case "$1" in
        "-v" | "--verbose" )
            verbose="true"
            ;;
        "-?" | "--help" )
            print_help
            
            exit $RESULT_OK
            ;;
        * )
            print_verbose "parameter " $1 " invalid. use patameter --help to get help."
            
            exit $PARAMETER_ERROR
            ;;
    esac

    shift
done
cp $ROOTPATH/*.sql /opt/gaussdb
chown gaussdba:dbgrp /opt/gaussdb/*.sql
su - gaussdba -c "gsql -d postgres -p $database_port -c \"CREATE USER apimgtdb WITH CREATEDB PASSWORD \\\"$userApimgtdbPassword\\\";\""
if [ $? -eq 0 ]; then
    print_verbose "< apimgtdb         > create                            [\033[32;49;1m OK \033[0m]"
else
    print_verbose "< apimgtdb         > create                            [\033[31;49;1m FAIL \033[0m]"
    exit $RESULT_ERROR 
fi

dbname=postgres
sql="CREATE database WSO2AM_DB"
createcommand_file_c
result=$(expect $command_file)
ret=$?
if [ $ret -eq 0 ]; then
    print_verbose "< wso2am_db        > create                            [\033[32;49;1m OK \033[0m]"
else
    if [ $ret -eq 4 ]; then
        print_verbose "< wso2am_db        > create                            [\033[32;49;1m OK \033[0m]"
    else
        print_verbose "$result"
        print_verbose "< wso2am_db        > create                            [\033[31;49;1m FAIL \033[0m]"
        rm -rf $command_file
        exit $RESULT_ERROR 
    fi
fi

rm -rf $command_file

# add schema for WSO2AM_DB
dbname=WSO2AM_DB
sql="create schema apimgtdb"
createcommand_file_c
result=$(expect $command_file)
ret=$?
rm -rf $command_file
if [ $ret -eq 0 ]; then
    print_verbose "< WSO2AM_DB schema > create                            [\033[32;49;1m OK \033[0m]"
else
    print_verbose "< WSO2AM_DB schema > create                            [\033[31;49;1m FAIL \033[0m]"
    exit $RESULT_ERROR 
fi

dbname=postgres
sql="CREATE database WSO2CARBON_DB"
createcommand_file_c
result=$(expect $command_file)
ret=$?
if [ $ret -eq 0 ]; then
    print_verbose "< wso2carbon_db    > create                            [\033[32;49;1m OK \033[0m]"
else
    if [ $ret -eq 4 ]; then
        print_verbose "< wso2carbon_db    > create                            [\033[32;49;1m OK \033[0m]"
    else
        print_verbose "$result"
        print_verbose "< wso2carbon_db    > create                            [\033[31;49;1m FAIL \033[0m]"
        rm -rf $command_file
        exit $RESULT_ERROR 
    fi
fi
rm -rf $command_file

# add schema for WSO2CARBON_DB
dbname=WSO2CARBON_DB
sql="create schema apimgtdb"
createcommand_file_c
result=$(expect $command_file)
ret=$?
rm -rf $command_file
if [ $ret -eq 0 ]; then
    print_verbose "< WSO2CARBON_DB schema > create                        [\033[32;49;1m OK \033[0m]"
else
    print_verbose "< WSO2CARBON_DB schema > create                        [\033[31;49;1m FAIL \033[0m]"
    exit $RESULT_ERROR 
fi

# REVOKE CREATE ON SCHEMA
revoke_from_public postgres
revoke_from_public WSO2AM_DB
revoke_from_public WSO2CARBON_DB


su - gaussdba -c "gsql -d WSO2CARBON_DB -p $database_port -Fp -f /opt/gaussdb/wso2carbon_db.sql;" >> /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_verbose "< wso2carbon_db    > create                            [\033[32;49;1m OK \033[0m]"
else
    print_verbose "< wso2carbon_db    > create                            [\033[31;49;1m FAIL \033[0m]"
    exit $RESULT_ERROR 
fi

dbname=WSO2AM_DB
sql="/opt/gaussdb/postgresql_GN.sql"
createcommand_file_f
result=$(expect $command_file)
ret=$?
if [ $ret -eq 0 ]; then
    print_verbose "< GN sql           > init                              [\033[32;49;1m OK \033[0m]"
else
    print_verbose "$ret"
    print_verbose "< GN sql           > init                              [\033[31;49;1m FAIL \033[0m]"
    rm -rf $command_file
    exit $RESULT_ERROR 
fi
rm -rf $command_file

dbname=WSO2AM_DB
sql="/opt/gaussdb/postgresql_AM.sql"
createcommand_file_f
result=$(expect $command_file)
ret=$?
if [ $ret -eq 0 ]; then
    print_verbose "< AM sql           > init                              [\033[32;49;1m OK \033[0m]"
else
    print_verbose "$ret"
    print_verbose "< AM sql           > init                              [\033[31;49;1m FAIL \033[0m]"
    rm -rf $command_file
    exit $RESULT_ERROR 
fi
rm -rf $command_file

dbname=WSO2AM_DB
sql="/opt/gaussdb/postgresql_ID.sql"
createcommand_file_f
result=$(expect $command_file)
ret=$?
if [ $ret -eq 0 ]; then
    print_verbose "< ID sql           > init                              [\033[32;49;1m OK \033[0m]"
else
    print_verbose "< ID sql           > init                              [\033[31;49;1m FAIL \033[0m]"
    exit $RESULT_ERROR 
fi
rm -rf $command_file

dbname=WSO2AM_DB
sql="/opt/gaussdb/apimgt_supplement.sql"
createcommand_file_f
result=$(expect $command_file)
ret=$?
if [ $ret -eq 0 ]; then
    print_verbose "< apimgt DB        > init                              [\033[32;49;1m OK \033[0m]"
else
    print_verbose "$ret"
    print_verbose "< apimgt DB        > init                              [\033[31;49;1m FAIL \033[0m]"
    rm -rf $command_file
    exit $RESULT_ERROR 
fi
rm -rf $command_file

dbname=WSO2AM_DB
sql="/opt/gaussdb/caas.sql"
createcommand_file_f
result=$(expect $command_file)
ret=$?
if [ $ret -eq 0 ]; then
    print_verbose "< CASS DB          > init                              [\033[32;49;1m OK \033[0m]"
else
    print_verbose "< CASS DB          > init                              [\033[31;49;1m FAIL \033[0m]"
    rm -rf $command_file
    exit $RESULT_ERROR 
fi
rm -rf $command_file

dbname=WSO2AM_DB
sql="/opt/gaussdb/dustman.sql"
createcommand_dustman
result=$(expect $command_file)
ret=$?
if [ $ret -eq 0 ]; then
    print_verbose "< TIME TASK        > add                               [\033[32;49;1m OK \033[0m]"
else
    print_verbose "$ret"
    print_verbose "< TIME TASK        > add                               [\033[31;49;1m FAIL \033[0m]"
    exit $RESULT_ERROR 
fi
rm -rf $command_file


dbname=WSO2AM_DB
sql="INSERT INTO AM_STATISTICS_UPLOAD_INFO (UPLOAD_TIME) VALUES (to_date(to_char(sysdate - 1,'yyyy-MM-dd'),'yyyy-mm-dd'))"
createcommand_file_c
result=$(expect $command_file)
ret=$?
if [ $ret -ne 0 ]; then
    exit $RESULT_ERROR
fi
rm -rf $command_file

if [ -f $ROOTPATH/../system/caas ]; then
    # set environment vlue for sys.trace.message.switch 
    dbname=WSO2AM_DB
    sql="INSERT INTO AM_ENV (NAME,VALUE,READONLY) VALUES('sys.trace.message.switch','off',0)"
    createcommand_file_c
    result=$(expect $command_file)
    ret=$?
    if [ $ret -ne 0 ]; then
        exit $RESULT_ERROR 
    fi
    rm -rf $command_file
fi

sh $ROOTPATH/insert_env.sh gaussdba $database_port $userApimgtdbPassword
if [ $? -eq 0 ]; then
    print_verbose "< ENV              > add                               [\033[32;49;1m OK \033[0m]"
else
    print_verbose "< ENV              > add                               [\033[31;49;1m FAIL \033[0m]"
    rm -rf $command_file
    exit $RESULT_ERROR 
fi

rm -f /opt/gaussdb/*.sql
chmod o-rwx /opt/gaussdb/app/ -R

exit $RESULT_OK
