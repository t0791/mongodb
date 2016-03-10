mysql-scripts:
  file.recurse:
    - name: /var/paas/scripts/mysql
    - source: salt://paas-common/mysql/files
    - makedirs: true
    - file-mode: 640
    - dir-mode: 640

mysql-copy-mysql_init:
  file.managed:
    - name: /var/paas/scripts/mysql/jobs/config/mysql_init
    - source: salt://paas-common/mysql/files/jobs/config/mysql_init
    - makedirs: true
    - mode: 640

mysql-copy-configure.sh:
  file.managed:
    - name: /var/paas/scripts/mysql/scripts/configure.sh
    - source: salt://paas-common/mysql/files/scripts/configure.sh
    - makedirs: true
    - mode: 640

mysql-install:
  cmd.run:
    - name: '/bin/bash install.sh'
    - cwd: /var/paas/scripts/mysql/scripts
    - env:
      - os: '{{ grains['os'] }}'
      - install_scene: '{{ pillar['install_scene'] }}'
{% if pillar['install_mode'] == 'cluster' %}
      - master_ips: '{{ pillar['mha']['master_ips'] }}'
      - slave_ips: '{{ pillar['mha']['slave_ips'] }}'
      - manager_slave_ips: '{{ pillar['mha']['manager_slave_ips'] }}'
      - mysql_chroot_dir: '/var/paas/chroot'
{% else %}
      - mysql_chroot_dir: '/var/chroot'
{% endif %}
      - mysql_user: '{{ pillar['mysql']['mysql_user'] }}'
      - mysql_user_passwd: '{{ pillar['mysql']['mysql_user_password'] }}'
      - mysql_port: '{{ pillar['mysql']['mysql_port'] }}'
      - mysql_innodb_log_file_size: '{{ pillar['mysql']['mysql_innodb_log_file_size'] }}'
      - mysql_max_connections: '{{ pillar['mysql']['mysql_max_connections'] }}'
      - mysql_max_allowed_packet: '{{ pillar['mysql']['mysql_max_allowed_packet'] }}'
      - mysql_max_queries_per_hour: '{{ pillar['mysql']['mysql_max_queries_per_hour'] }}'
      - mysql_max_updates_per_hour: '{{ pillar['mysql']['mysql_max_updates_per_hour'] }}'
      - mysql_max_connections_per_hour: '{{ pillar['mysql']['mysql_max_connections_per_hour'] }}'
      - mysql_max_user_connections: '{{ pillar['mysql']['mysql_max_user_connections'] }}'
      - mysql_admin_username: '{{ pillar['mysql']['mysql_admin_username'] }}'
      - mysql_interactive_timeout: '{{ pillar['mysql']['mysql_interactive_timeout'] }}'
      - mysql_wait_timeout: '{{ pillar['mysql']['mysql_wait_timeout'] }}'
      - mysql_expire_logs_days: '{{ pillar['mysql']['mysql_expire_logs_days'] }}'
      - mysql_audit_log_policy: '{{ pillar['mysql']['mysql_audit_log_policy'] }}'
      - mysql_audit_log_format: '{{ pillar['mysql']['mysql_audit_log_format'] }}'
      - mysql_audit_log_file: '{{ pillar['mysql']['mysql_audit_log_file'] }}'
      - mysql_audit_log_rotate_on_size: '{{ pillar['mysql']['mysql_audit_log_rotate_on_size'] }}'
      - mysql_audit_log_rotations: '{{ pillar['mysql']['mysql_audit_log_rotations'] }}'
      - mysql_admin_password: '{{ pillar['mysql']['mysql_admin_password'] }}'
      - ccdb_name: '{{ pillar['mysql']['ccdb_name'] }}'
      - ccdb_user: '{{ pillar['mysql']['ccdb_user'] }}'
      - ccdb_password: '{{ pillar['mysql']['ccdb_password'] }}'
      - eventbusdb_name: '{{ pillar['mysql']['eventbusdb_name'] }}'
      - eventbusdb_user: '{{ pillar['mysql']['eventbusdb_user'] }}'
      - eventbusdb_password: '{{ pillar['mysql']['eventbusdb_password'] }}'
      - accessdb_name: '{{ pillar['mysql']['accessdb_name']}}'
      - accessdb_user: '{{ pillar['mysql']['accessdb_user']}}'
      - accessdb_password: '{{ pillar['mysql']['accessdb_password']}}'
      - uaadb_name: '{{ pillar['mysql']['uaadb_name'] }}'
      - uaadb_user: '{{ pillar['mysql']['uaadb_user'] }}'
      - uaadb_password: '{{ pillar['mysql']['uaadb_password'] }}'
      - paasdb_name: '{{ pillar['mysql']['paasdb_name'] }}'
      - paasdb_user: '{{ pillar['mysql']['paasdb_user'] }}'
      - paasdb_password: '{{ pillar['mysql']['paasdb_password'] }}'
      - servicemgrdb_name: '{{ pillar['mysql']['servicemgrdb_name'] }}'
      - servicemgrdb_user: '{{ pillar['mysql']['servicemgrdb_user'] }}'
      - servicemgrdb_password: '{{ pillar['mysql']['servicemgrdb_password'] }}'
      - deploymgrdb_name: '{{ pillar['mysql']['deploymgrdb_name'] }}'
      - deploymgrdb_user: '{{ pillar['mysql']['deploymgrdb_user'] }}'
      - deploymgrdb_password: '{{ pillar['mysql']['deploymgrdb_password'] }}'
      - packagedb_name: '{{ pillar['mysql']['packagedb_name'] }}'
      - packagedb_user: '{{ pillar['mysql']['packagedb_user'] }}'
      - packagedb_password: '{{ pillar['mysql']['packagedb_password'] }}'
      - gitdb_name: '{{ pillar['mysql']['gitdb_name'] }}'
      - gitdb_user: '{{ pillar['mysql']['gitdb_user'] }}'
      - gitdb_password: '{{ pillar['mysql']['gitdb_password'] }}'
      - tenantmgrdb_name: '{{ pillar['mysql']['tenantmgrdb_name'] }}'
      - tenantmgrdb_user: '{{ pillar['mysql']['tenantmgrdb_user'] }}'
      - tenantmgrdb_password: '{{ pillar['mysql']['tenantmgrdb_password'] }}'
      - appmgrdb_name: '{{ pillar['mysql']['appmgrdb_name'] }}'
      - appmgrdb_user: '{{ pillar['mysql']['appmgrdb_user'] }}'
      - appmgrdb_password: '{{ pillar['mysql']['appmgrdb_password'] }}'
      - appbrokerdb_name: '{{ pillar['mysql']['appbrokerdb_name'] }}'
      - appbrokerdb_user: '{{ pillar['mysql']['appbrokerdb_user'] }}'
      - appbrokerdb_password: '{{ pillar['mysql']['appbrokerdb_password'] }}'
      - brdb_name: '{{ pillar['mysql']['brdb_name'] }}'
      - brdb_user: '{{ pillar['mysql']['brdb_user'] }}'
      - brdb_password: '{{ pillar['mysql']['brdb_password'] }}'
      - orchdb_name: '{{ pillar['mysql']['orchdb_name'] }}'
      - orchdb_user: '{{ pillar['mysql']['orchdb_user'] }}'
      - cc_ips: '{{ pillar[grains['zone']]['cloud_controller_ng_ips'] }}'
      - eventbus_ips: '{{ pillar['ops_mgr']['redis_ips'] }}'
      - paasapi_ips: '{{ pillar['paasapi_ips'] }}'
      - servicemgr_ips: '{{ pillar['servicemgr_ips'] }}'
      - deploymgr_ips: '{{ pillar['deploy_mgr']['deploy_mgr_ip'] }}'
      - tenantmgr_ips: '{{ pillar['tenantmgr_ips'] }}'
      - appmgr_ips: '{{ pillar['appmgr_ips'] }}'
      - om_ops_server_ip: '{{ pillar['om_ops_mgr']['om_ops_server_ip'] }}'
      - ops_proxy_ips: '{{ pillar['ops_mgr']['zookeeper_endpoint'] }}'
{% if pillar['install_scene'] == "private" or pillar['install_scene'] == "gts" or pillar['install_scene'] == "icbc" %}
      - uaa_ips: '{{ pillar['uaa_ips'] }}'
      - package_ips: '{{ pillar['package_ips'] }}'
{% endif %}

mysql-clean:
  cmd.run:
    - name: rm -rf mysql
    - cwd: /var/paas/scripts

mysql-logrotate.conf:
  file.managed:
    - name: /var/paas/jobs/logrotate/conf/mysql_logrotate.conf
    - source: salt://paas-common/mysql/files/logrotate/logrotate.conf
    - makedirs: true
    - mode: 600

mysql-crontab.conf:
  file.managed:
    - name: /var/paas/jobs/logrotate/crontab.d/mysql_crontab.conf
    - source: salt://paas-common/mysql/files/logrotate/crontab.conf
    - makedirs: true
    - mode: 600
