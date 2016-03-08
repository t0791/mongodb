#!/bin/bash
# Copyright (c) Huawei Technologies Co., Ltd. 2014- . All rights reserved.  
# Author:  zhaichunying 00141106
#
# Description £ºinit user for store
#

UTILITY="$0"
UTILITY_NAME=${UTILITY#*/}
verbose="false"
ROOTPATH=$(cd "$(dirname "$0")"; pwd)
AMUSER="topus"
JDK_VERSION=jdk
java_path=/opt/$AMUSER/$JDK_VERSION/bin

RESULT_OK=0
RESULT_ERROR=1
PARAMETER_ERROR=2

crypto_jar=$ROOTPATH/../../install/com.huawei.am.igt.pwdjobexecutor-1.0.0.jar

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

######### start wso2 ##################
su - topus -c "/bin/bash /opt/topus/apimgt/bin/wso2server.sh -Dsetup  >> /dev/null 2>&1 &"
if [ $? -ne 0 ]; then
    echo -e "< platform         > start                             [\033[31;49;1m FAIL \033[0m]"
    exit $RESULT_ERROR 
fi

sleep 60

########## init user ##################
userApimgtdbPassword=$(sh $ROOTPATH/../../install/get_password.sh -a DB_user.apimgtdb.password)
echo "#!/bin/bash" > $ROOTPATH/temp.sh
chmod +x $ROOTPATH/temp.sh
result=`$java_path/java -jar $crypto_jar "userApimgtdbPassword=$userApimgtdbPassword" $ROOTPATH/init_user_cmd.sh $ROOTPATH/../../install/crypto 2>> /dev/null`
if [ $? -eq 0 ]; then
    print_verbose "< User sql           > init                            [\033[32;49;1m OK \033[0m]"
else
    su - topus -c "/bin/bash /opt/topus/apimgt/bin/wso2server.sh -stop" >> /dev/null 2>&1
    print_verbose "< User sql           > init                            [\033[31;49;1m FAIL \033[0m]"
    exit $RESULT_ERROR 
fi

########## stop wso2 ##################
su - topus -c "/bin/bash /opt/topus/apimgt/bin/wso2server.sh -stop" >> /dev/null 2>&1
if [ $? -ne 0 ]; then
    print_verbose "< platform         > stop                              [\033[31;49;1m FAIL \033[0m]"
    exit $RESULT_ERROR 
fi
echo -e "< platform         > stop                              [\033[32;49;1m OK \033[0m]"
exit $RESULT_OK
