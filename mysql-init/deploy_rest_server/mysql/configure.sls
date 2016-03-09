deploy-mgr-mysql-configure.sh:
  file.managed:
    - name: /var/paas/scripts/mysql/scripts/configure.sh
    - source: salt://deploy_rest_server/mysql/files/scripts/configure.sh
    - makedirs: True
    - force: True

#deploy-mgr-mysql-trash.sh:
#  file.managed:
#    - name: /var/paas/scripts/mysql/scripts/trash.sh
#    - source: salt://deploy_rest_server/mysql/files/scripts/trash.sh
#    - makedirs: True
#    - force: True

deploy-mgr-mysql-configure:
  cmd.run:
    - name: 'bash /var/paas/common/wait_monit_status.sh && /bin/bash configure.sh'
    - cwd: /var/paas/scripts/mysql/scripts
    - env:
{% if pillar['install_mode'] == 'cluster' %}
      - mysql_chroot_dir: '/var/paas/chroot'
{% else %}
      - mysql_chroot_dir: '/var/chroot'
{% endif %}
      - deploymgrdb_name: '{{ pillar['cde_mysql']['deploymgrdb_name'] }}'
      - deploymgrdb_user: '{{ pillar['cde_mysql']['deploymgrdb_user'] }}'
      - deploymgrdb_password: '{{ pillar['cde_mysql']['deploymgrdb_password'] }}'
      - deploymgr_ips: '{{ pillar['deploy_mgr']['deploy_mgr_ip'] }}'
      - mysql_port: '{{ pillar['cde_mysql']['mysql_port'] }}'
      - mysql_admin_username: '{{ pillar['cde_mysql']['mysql_admin_username'] }}'
      - mysql_admin_password: '{{ pillar['cde_mysql']['mysql_admin_password'] }}'
      - mysql_max_queries_per_hour: '{{ pillar['cde_mysql']['mysql_max_queries_per_hour'] }}'
      - mysql_max_updates_per_hour: '{{ pillar['cde_mysql']['mysql_max_updates_per_hour'] }}'
      - mysql_max_connections_per_hour: '{{ pillar['cde_mysql']['mysql_max_connections_per_hour'] }}'
      - mysql_max_user_connections: '{{ pillar['cde_mysql']['mysql_max_user_connections'] }}'
      - mysql_init_file: /var/vcap/chroot/mysql/var/vcap/packages/mysql/config/mysql_init
      - mysql_config: /var/vcap/chroot/mysql/var/vcap/packages/mysql/config
      - component: mysql

#deploy-mgr-mysql-restart:
#  cmd.run:
#    - name: 'bash /var/paas/common/wait_monit_status.sh && /var/paas/monit/bin/monit restart mysql'
#    - env:
#        component: mysql


#deploy-mgr-mysql-trash:
#  cmd.run:
#    - name: 'bash /var/paas/scripts/mysql/scripts/trash.sh'
#    - env:
#      - mysql_init_file: /var/vcap/chroot/mysql/var/vcap/packages/mysql/config/mysql_init
#      - mysql_config: /var/vcap/chroot/mysql/var/vcap/packages/mysql/config

mysql-clean:
  cmd.run:
    - name: rm -rf mysql
    - cwd: /var/paas/scripts
