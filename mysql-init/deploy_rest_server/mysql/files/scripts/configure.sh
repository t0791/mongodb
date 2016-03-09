# source env

#source /var/paas/config/global.env
#source /var/paas/config/$NAME/${NAME}.env
set -e

HOST_IP=127.0.0.1

cat >mysql-auth.cnf <<EOF
[client]
user=$mysql_admin_username
port=$mysql_port
host=$HOST_IP
password=$mysql_admin_password
EOF

createSQLFile() {
cat >query.sql <<EOF
CREATE DATABASE IF NOT EXISTS $1; \
    GRANT ALL PRIVILEGES ON $1.* TO '$2'@'$3' IDENTIFIED BY '$4' WITH MAX_QUERIES_PER_HOUR $mysql_max_queries_per_hour \
    MAX_UPDATES_PER_HOUR $mysql_max_updates_per_hour MAX_CONNECTIONS_PER_HOUR $mysql_max_connections_per_hour MAX_USER_CONNECTIONS $mysql_max_user_connections; FLUSH PRIVILEGES;
EOF
}

for deploymgr_ip in $deploymgr_ips
do
    createSQLFile "$deploymgrdb_name" "$deploymgrdb_user" "$deploymgr_ip" "$deploymgrdb_password"
    sudo ${mysql_chroot_dir}/mysql/var/vcap/packages/mysql/bin/mysql --defaults-extra-file=mysql-auth.cnf < query.sql
    rm -f query.sql
done

rm -f mysql-auth.cnf
