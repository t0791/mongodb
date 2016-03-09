#!/bin/bash

NAME=mysql
PACKAGE_DIR=/var/vcap/packages/$NAME
RUN_DIR=/var/vcap/sys/run/$NAME
LOG_DIR=/var/vcap/sys/log/$NAME
JOB_DIR=/var/vcap/jobs/$NAME
MONIT_LOG_DIR=/var/vcap/sys/log/monit
TMP_DIR=$PACKAGE_DIR/tmp

CHROOT_DIR=/var/paas/chroot/$NAME
CHROOT_PACKAGE_DIR=$CHROOT_DIR/var/vcap/packages/$NAME
CHROOT_RUN_DIR=$CHROOT_DIR/var/vcap/sys/run/$NAME
CHROOT_LOG_DIR=$CHROOT_DIR/var/vcap/sys/log/$NAME
CHROOT_DATA_DIR=$CHROOT_DIR/var/vcap/store/$NAME
CHROOT_TMP_DIR=$CHROOT_PACKAGE_DIR/tmp

# create dir
if [ ! -d /var/vcap ]; then
  sudo ln -s /var/paas /var/vcap
fi

mkdir -p $PACKAGE_DIR ${PACKAGE_DIR}/config
mkdir -p $RUN_DIR
mkdir -p $LOG_DIR
mkdir -p $JOB_DIR
mkdir -p $MONIT_LOG_DIR
mkdir -p $TMP_DIR

# create package
(
  cd /var/paas/packages

  tar xzf $NAME.tgz
  tar xzf mysql.tar.gz -C $PACKAGE_DIR
  rm -f mysql.tar.gz
  rm -rf $NAME.tgz
)

# source env
#source /var/paas/config/global.env
#source /var/paas/config/$NAME/${NAME}.env

# create jobs
chmod -R o-rwx,g-rwx /var/paas/scripts/mysql/jobs/
cp -r /var/paas/scripts/mysql/jobs/* $JOB_DIR
rm -f $JOB_DIR/config/*.mysql_init
chmod 750 $JOB_DIR/bin/*
chmod 640 $JOB_DIR/config/*

# update jobs files
BIN=$(cd $(dirname $0); pwd)
bash $BIN/configure.sh

mv ${JOB_DIR}/config/* ${PACKAGE_DIR}/config/
cp -f ${PACKAGE_DIR}/config/my-default.cnf ${PACKAGE_DIR}/support-files
cp -f ${PACKAGE_DIR}/config/my-default.cnf ${PACKAGE_DIR}/my.cnf
chmod  o-rwx,g-rwx ${PACKAGE_DIR}/my.cnf
chmod  o-rwx,g-rwx ${PACKAGE_DIR}/support-files/my-default.cnf
chmod  -R o-rwx,g-rwx ${PACKAGE_DIR}/config/

if [ "${mysql_user}" != "paas" ]; then

#TBD: Password may be visible in plain text. need to handle
  sudo useradd -r -g paas -m -s /bin/bash ${mysql_user} -p $(echo "${mysql_user_passwd}" | openssl passwd -1 -stdin)
  sudo sed -i -e "\$aAllowUsers ${mysql_user}" /etc/ssh/sshd_config
  if [ $os == 'Ubuntu' ]; then
    sudo service ssh restart
  elif [ $os == 'EulerOS' ]; then
    sudo sed -i -e "\$aAllowUsers paas" /etc/ssh/sshd_config
    sudo service sshd restart
  fi

  sed -i "s/^mysql_user=.*/mysql_user=${mysql_user}/g" $JOB_DIR/bin/mysql_ctl
  echo 'umask 0700; export UMASK=0600; export UMASK_DIR=0700' | sudo tee /home/${mysql_user}/.profile
fi

# set file permissions
result=`grep "umask 077" ~/.profile |wc -l`
if [ $result -eq 0 ]; then
echo 'umask 077' >> ~/.profile
fi
echo 'export UMASK=0600' >> ~/.profile
echo 'export UMASK_DIR=0700' >> ~/.profile
source ~/.profile

# create monitrc
mkdir -p /var/paas/monit/job
cp /var/paas/scripts/$NAME/monit/$NAME.monitrc /var/paas/monit/job/$NAME.monitrc

# setup chroot environment
mkdir -p $CHROOT_DIR
pushd ${CHROOT_DIR} > /dev/null
mkdir -p etc
mkdir -p $CHROOT_PACKAGE_DIR $CHROOT_RUN_DIR $CHROOT_LOG_DIR $CHROOT_DATA_DIR

cp /etc/localtime etc
echo "127.0.0.1 localhost" > etc/hosts

grep "^${mysql_user}:" /etc/passwd > etc/passwd


# for reading etc/passwd and etc/hosts
if [ $os == 'Ubuntu' ]; then
  mkdir -p lib
  sudo cp `sudo find /lib/ -name libnss_compat.so.2` lib/
  sudo cp `sudo find /lib/ -name libnss_files.so.2` lib/
  sudo chown -R paas:paas lib
elif [ $os == 'EulerOS' ]; then
  mkdir -p lib64
  sudo cp `sudo find /lib64/ -name libnss_compat.so.2` lib64/
  sudo cp `sudo find /lib64/ -name libnss_files.so.2` lib64/
  sudo chown -R paas:paas lib64
else
  echo "Unsupport os, os type: [$os]"
  exit 1
fi

mv $PACKAGE_DIR/* $CHROOT_PACKAGE_DIR
popd > /dev/null

# Don't use system files, if any exist in the system
if [ $os == 'Ubuntu' ]; then
  sudo rm -rf /etc/mysql/
elif [ $os == 'EulerOS' ]; then
  sudo rm -rf /etc/my.cnf*
fi

# install db
${CHROOT_PACKAGE_DIR}/scripts/mysql_install_db --user=${mysql_user} --tmpdir=${CHROOT_TMP_DIR} --basedir=${CHROOT_PACKAGE_DIR} --datadir=${CHROOT_DATA_DIR}

# update file permissions
chown -R paas:paas /var/vcap/
chmod -R o-rwx,g-w /var/vcap/
chmod -R o-rwx,g-rwx ${CHROOT_DATA_DIR}

if [ "x$MYSQL_HISTFILE" == "x" ]; then
  echo 'export MYSQL_HISTFILE=/dev/null' >> ~/.profile
  source ~/.profile
fi

echo $mysql_port > $JOB_DIR/config/port
chmod 600 $JOB_DIR/config/port


######################### add log rotate crontab job
mkdir -p  -m 750 ${JOB_DIR}/logrotate
touch ${JOB_DIR}/logrotate/logrotate.conf
chmod 640 ${JOB_DIR}/logrotate/logrotate.conf
cat > ${JOB_DIR}/logrotate/logrotate.conf <<EOF
    /var/vcap/sys/log/mysql/*.log
    /var/vcap/sys/log/compilation/*.log
    /var/paas/monit/*.log
    /var/paas/sys/log/mysql/*.log
    /var/paas/sys/log/*.log
    /var/paas/sys/log/system/rsyslog/*.log
    $CHROOT_DIR/var/vcap/sys/log/mysql/*.log
    {
        missingok
        rotate 20
        compress
        copytruncate
        notifempty
        size 50M
        sharedscripts
        postrotate
            sudo service rsyslog restart
        endscript
    }
EOF
touch ${JOB_DIR}/logrotate/crontab.conf
chmod 640 ${JOB_DIR}/logrotate/crontab.conf
sudo crontab -u root -l > ${JOB_DIR}/logrotate/crontab.conf
if [ `cat ${JOB_DIR}/logrotate/crontab.conf | grep -c "${JOB_DIR}/logrotate/logrotate.conf"` == 0 ];then
cat >> ${JOB_DIR}/logrotate/crontab.conf <<EOF
    45 * * * * su paas -c "/usr/sbin/logrotate ${JOB_DIR}/logrotate/logrotate.conf 2>/dev/null"
EOF
  fi
###################### start logrotate crontab job

sudo crontab -u root ${JOB_DIR}/logrotate/crontab.conf
sudo find /var/paas -name "*.log" -exec chmod 640 {} \;

echo "export PATH=\$PATH:${CHROOT_PACKAGE_DIR}/bin" >> ~/.profile
sudo chown -R ${mysql_user}:paas /var/paas/chroot
sudo chmod 0770 /var/paas/chroot
sudo chmod 0750 ${CHROOT_DIR}
sudo chmod 0750 ${CHROOT_DIR}/var
sudo chmod 0750 ${CHROOT_DIR}/var/vcap
sudo chmod 0750 ${CHROOT_DIR}/var/vcap/packages
sudo chmod 0750 ${CHROOT_DIR}/var/vcap/packages/mysql
sudo chmod 0750 ${CHROOT_DIR}/var/vcap/sys
sudo chmod 0750 ${CHROOT_DIR}/var/vcap/sys/run
sudo chmod 0750 ${CHROOT_DIR}/var/vcap/sys/run/mysql
