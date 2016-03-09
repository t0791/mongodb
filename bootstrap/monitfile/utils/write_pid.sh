# **************************************************************************** #
# Description : find process and write pid to file, wait if process is not found
# Parameter   : $1 -- process name, $2 -- saving path of current PID
# Return      : none
# Since       : process monit feature
# Others      :
# **************************************************************************** #
function writepid()
{
    PROCNAME=$1
    PIDFILE=$2
    timeout=30 #second
    thread_num=0

    while [ $thread_num -ne 1 ];do
           thread_num=`ps -ef |grep "$PROCNAME"|grep -v grep|wc -l`
           if [ $thread_num -ne 1 ]; then
              sleep 1
              echo -n "-"
           fi
           timeout=$((timeout-1))
           if [ $timeout -eq 0 ]; then
              return 1
           fi
    done

    ps -ef |grep "$PROCNAME"|grep -v grep|awk '{print $2}' >$PIDFILE
    return 0
}
