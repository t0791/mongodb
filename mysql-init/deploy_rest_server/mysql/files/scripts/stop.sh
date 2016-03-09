#!/bin/bash

for i in {1..60}; do
  count_pending=`/var/paas/monit/bin/monit summary |grep mysql |grep pending | wc -l`
  if [ $count_pending -eq 0 ]; then
    echo "continue stop action"
    break
  fi
  sleep 5
done

/var/paas/monit/bin/monit stop mysql

mysql_stopped=0
for i in {1..60}; do
  if ! (/var/paas/monit/bin/monit summary |grep mysql |grep -v -E "not monitored$"); then
    mysql_stopped=1
    break
  fi
  sleep 5
done

if [ "$mysql_stopped" == "0" ]; then
  echo "mysql not stopping, plz check"
#  exit 1
fi

#Ensure mysql is gone even when monit file is removed for some reason
sudo pkill mysql

folders=(
  "/var/vcap/packages/mysql"
  "/var/vcap/sys/run/mysql"
  "/var/vcap/sys/log/mysql"
  "/var/vcap/jobs/mysql"
  "/var/paas/chroot"
)

for eachfolder in "${folders[@]}"; do
  sudo rm -rf $eachfolder
done

if [ "${mysql_user}" != "paas" ]; then
  sudo sed -i "/^AllowUsers ${mysql_user}$/d" /etc/ssh/sshd_config

  if [ $os == 'Ubuntu' ]; then
    sudo service ssh restart
  elif [ $os == 'EulerOS' ]; then
    sudo service sshd restart
  fi

  sudo userdel -r -f ${mysql_user}
fi

rm /var/paas/monit/job/mysql.monitrc

/var/paas/monit/bin/monit reload
