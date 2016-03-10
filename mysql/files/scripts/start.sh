#!/bin/bash

/var/paas/monit/bin/monit reload

PACKAGE_DIR=${mysql_chroot_dir}/mysql/var/vcap/packages/mysql
SETUP_LOG=/var/vcap/sys/log/mysql/mysql_setup.log

cat >mysql-auth.cnf <<EOF
[client]
user=$mysql_admin_username
port=$mysql_port
host=127.0.0.1
password=$mysql_admin_password
EOF

status=0
for i in {1..60}
do
  sudo ${mysql_chroot_dir}/mysql/var/vcap/packages/mysql/bin/mysql --defaults-extra-file=mysql-auth.cnf -e "show status;" >> /dev/null 2>&1
  if [ $? -eq 0 ]; then
    status=1
    break;
  fi
  sleep 5
done

rm -f mysql-auth.cnf

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