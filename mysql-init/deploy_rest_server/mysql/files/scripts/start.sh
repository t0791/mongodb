#!/bin/bash

/var/paas/monit/bin/monit reload

/var/vcap/jobs/mysql/bin/mysql_ctl start

PACKAGE_DIR=/var/paas/chroot/mysql/var/vcap/packages/mysql
SETUP_LOG=/var/vcap/sys/log/mysql/mysql_setup.log

status=0
for i in {1..60}
do
  sudo /var/paas/chroot/mysql/var/vcap/packages/mysql/bin/mysql -h 127.0.0.1 -P $mysql_port -u$mysql_admin_username -p$mysql_admin_password -e "show status;" >> $SETUP_LOG
  if [ $? -eq 0 ]; then
    status=1
    break;
  fi
  sleep 5
done

if [ $status -eq 0 ]; then
  echo "mysql start up failed" >> $SETUP_LOG
  exit 1
else
  sudo sed -i '1,$d' ${PACKAGE_DIR}/config/mysql_init
  sudo sed -i '1,$d' ${PACKAGE_DIR}/bin/mysqlaccess.conf

  echo "mysql start up success" >> $SETUP_LOG
fi

chmod 640 $SETUP_LOG
sudo chmod o-rwx,g-w -R /var/vcap/
sudo find /var/paas -name "*.log" -exec chmod 640 {} \;
