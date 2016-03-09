# source env
NAME=mysql
#source /var/paas/config/global.env
#source /var/paas/config/$NAME/${NAME}.env

JOB_DIR=/var/vcap/jobs/$NAME
HOST_IP=`ip -4 -o addr | grep eth. | head -n1 | awk '{split($4,a,"/");print a[1]}' | tr -d '\n\r'`

# update config
CONF_FILE=${JOB_DIR}/config/my-default.cnf
sed -i "s|<%= mysql.port %>|$mysql_port|g" ${CONF_FILE}
sed -i "s|<%= mysql.innodb_log_file_size %>|$mysql_innodb_log_file_size|g" ${CONF_FILE}
sed -i "s|<%= mysql.max_connections %>|$mysql_max_connections|g" ${CONF_FILE}
sed -i "s|<%= mysql.max_allowed_packet %>|$mysql_max_allowed_packet|g" ${CONF_FILE}
sed -i "s|<%= mysql.user %>|$mysql_user|g" ${CONF_FILE}
sed -i "s|<%= bindaddress %>|$HOST_IP|g" ${CONF_FILE}

# update mysql_init
MYSQL_INIT_FILE=${JOB_DIR}/config/mysql_init
sed -i "s|<%= mysql.admin_username %>|$mysql_admin_username|g" ${MYSQL_INIT_FILE}
sed -i "s|<%= mysql.admin_password %>|$mysql_admin_password|g" ${MYSQL_INIT_FILE}
sed -i "s|<%= mysql_ip %>|127.0.0.1|g" ${MYSQL_INIT_FILE}

sed -i "s|<%= ccdb.name %>|$ccdb_name|g" ${MYSQL_INIT_FILE}
sed -i "s|<%= ccdb.user %>|$ccdb_user|g" ${MYSQL_INIT_FILE}
for cc_ip in $cc_ips
do
  sed -i "/CREATE DATABASE IF NOT EXISTS $ccdb_name/aGRANT ALL PRIVILEGES ON $ccdb_name.* \
TO '$ccdb_user'@'$cc_ip' IDENTIFIED BY '$ccdb_password' \
WITH MAX_QUERIES_PER_HOUR $mysql_max_queries_per_hour \
MAX_UPDATES_PER_HOUR $mysql_max_updates_per_hour \
MAX_CONNECTIONS_PER_HOUR $mysql_max_connections_per_hour \
MAX_USER_CONNECTIONS $mysql_max_user_connections;" ${MYSQL_INIT_FILE}
done
