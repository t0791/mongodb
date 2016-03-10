# source env
NAME=mysql

JOB_DIR=/var/vcap/jobs/$NAME

# update config
CONF_FILE=${JOB_DIR}/config/my-default.cnf
sed -i "s|<%= mysql.port %>|$mysql_port|g" ${CONF_FILE}
sed -i "s|<%= mysql.innodb_log_file_size %>|$mysql_innodb_log_file_size|g" ${CONF_FILE}
sed -i "s|<%= mysql.max_connections %>|$mysql_max_connections|g" ${CONF_FILE}
sed -i "s|<%= mysql.max_allowed_packet %>|$mysql_max_allowed_packet|g" ${CONF_FILE}
sed -i "s|<%= mysql.user %>|$mysql_user|g" ${CONF_FILE}
sed -i "s|<%= mysql.chroot_dir %>|${mysql_chroot_dir}|g" ${CONF_FILE}
sed -i "s|<%= mysql.interactive_timeout %>|${mysql_interactive_timeout}|g" ${CONF_FILE}
sed -i "s|<%= mysql.wait_timeout %>|${mysql_wait_timeout}|g" ${CONF_FILE}
sed -i "s|<%= mysql.expire_logs_days %>|${mysql_expire_logs_days}|g" ${CONF_FILE}
sed -i "s|<%= mysql.audit_log_policy %>|${mysql_audit_log_policy}|g" ${CONF_FILE}
sed -i "s|<%= mysql.audit_log_format %>|${mysql_audit_log_format}|g" ${CONF_FILE}
sed -i "s|<%= mysql.audit_log_file %>|${mysql_audit_log_file}|g" ${CONF_FILE}
sed -i "s|<%= mysql.audit_log_rotate_on_size %>|${mysql_audit_log_rotate_on_size}|g" ${CONF_FILE}
sed -i "s|<%= mysql.audit_log_rotations %>|${mysql_audit_log_rotations}|g" ${CONF_FILE}

# update mysql_init
MYSQL_INIT_FILE=${JOB_DIR}/config/mysql_init
sed -i "s|<%= mysql.admin_username %>|$mysql_admin_username|g" ${MYSQL_INIT_FILE}
sed -i "s|<%= mysql.admin_password %>|$mysql_admin_password|g" ${MYSQL_INIT_FILE}
sed -i "s|<%= mysql_ip %>|127.0.0.1|g" ${MYSQL_INIT_FILE}
sed -i "s|<%= mysql_max_queries_per_hour %>|$mysql_max_queries_per_hour|g" ${MYSQL_INIT_FILE}
sed -i "s|<%= mysql_max_updates_per_hour %>|$mysql_max_updates_per_hour|g" ${MYSQL_INIT_FILE}
sed -i "s|<%= mysql_max_connections_per_hour %>|$mysql_max_connections_per_hour|g" ${MYSQL_INIT_FILE}
sed -i "s|<%= mysql_max_user_connections %>|$mysql_max_user_connections|g" ${MYSQL_INIT_FILE}

if [ "$master_ips" != "" ]; then
  for master_ip in $master_ips
  do  
     sed -i 1"i\GRANT ALL PRIVILEGES ON *.* TO \'$mysql_admin_username\'@\'$master_ip\' IDENTIFIED BY \'$mysql_admin_password\' WITH MAX_QUERIES_PER_HOUR $mysql_max_queries_per_hour MAX_UPDATES_PER_HOUR $mysql_max_updates_per_hour MAX_CONNECTIONS_PER_HOUR $mysql_max_connections_per_hour MAX_USER_CONNECTIONS $mysql_max_user_connections GRANT OPTION;" ${MYSQL_INIT_FILE}
  done  
fi

if [ "$slave_ips" != "" ]; then
  for slave_ip in $slave_ips
  do
     sed -i 1"i\GRANT ALL PRIVILEGES ON *.* TO \'$mysql_admin_username\'@\'$slave_ip\' IDENTIFIED BY \'$mysql_admin_password\' WITH MAX_QUERIES_PER_HOUR $mysql_max_queries_per_hour MAX_UPDATES_PER_HOUR $mysql_max_updates_per_hour MAX_CONNECTIONS_PER_HOUR $mysql_max_connections_per_hour MAX_USER_CONNECTIONS $mysql_max_user_connections GRANT OPTION;" ${MYSQL_INIT_FILE}
  done
fi

if [ "$manager_slave_ips" != "" ]; then
  for manager_slave_ip in $manager_slave_ips
  do
     sed -i 1"i\GRANT ALL PRIVILEGES ON *.* TO \'$mysql_admin_username\'@\'$manager_slave_ip\' IDENTIFIED BY \'$mysql_admin_password\' WITH MAX_QUERIES_PER_HOUR $mysql_max_queries_per_hour MAX_UPDATES_PER_HOUR $mysql_max_updates_per_hour MAX_CONNECTIONS_PER_HOUR $mysql_max_connections_per_hour MAX_USER_CONNECTIONS $mysql_max_user_connections GRANT OPTION;" ${MYSQL_INIT_FILE}
  done
fi
