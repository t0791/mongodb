/var/paas/jobs/deploy_rest_server/bin/deploy_rest_server_ctl stop
rm -rf /var/paas/monit/job/deploy_rest_server.monitrc
rm -rf /var/paas/jobs/deploy_rest_server
RUN_DIR=/var/paas/sys/run/deploy_rest_server
PIDFILE=$RUN_DIR/deploy_rest_server.pid
PIDS=(`ps -ef |grep "./deploy-rest-server"|grep -v grep|grep -v ctl|awk '{print $2}'`)
if [ ! -z "$PIDS" ]; then
    for i in "${PIDS[@]}"
    do
       echo "kill process $PROC/$i"
       kill -9  $i
    done
fi

rm -f $PIDFILE
rm -rf /var/paas/sys/run/deploy_rest_server
rm -rf /var/paas/sys/log/deploy_rest_server
