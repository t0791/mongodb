deploy_rest_server_conf_app:
  file.managed:
    - name: /var/paas/jobs/deploy_rest_server/conf/app.conf
    - source: salt://deploy_rest_server/deploy_rest_server/files/config/app.conf
    - template: jinja
    - context: 
      httpaddr: {{ grains['ip4_interfaces']['eth0'][0] }}
      httpport: '{{ pillar['deploy_rest_server']['deploy_rest_server_port'] }}'
      db_scheme: {{ pillar['deploy_rest_server']['db_scheme'] }}
      usebss: {{ pillar['deploy_rest_server']['use_bss'] }}
      cf_api_version: {{ pillar['deploy_rest_server']['cf_api_version'] }}
      cf_admin_account_name: {{ pillar['deploy_rest_server']['cf_admin_account_name'] }}
    - makedirs: true
    - mode: 600

deploy_rest_server_conf_etcd:
  file.managed:
    - name: /var/paas/jobs/deploy_rest_server/conf/etcdConfig.json
    - source: salt://deploy_rest_server/deploy_rest_server/files/config/etcdConfig.json
    - makedirs: true
    - mode: 640

deploy_rest_server_conf_image:
  file.managed:
    - name: /var/paas/jobs/deploy_rest_server/conf/image.json
    - source: salt://deploy_rest_server/deploy_rest_server/files/config/image.json
    - makedirs: true
    - mode: 640

deploy_rest_server_conf_policytemplate:
  file.managed:
    - name: /var/paas/jobs/deploy_rest_server/conf/policytemplate.json
    - source: salt://deploy_rest_server/deploy_rest_server/files/config/policytemplate.json
    - makedirs: true
    - mode: 640

deploy_rest_server_config.sh:
  cmd.run:
    - name: '/bin/bash configure.sh'
    - cwd: /var/paas/jobs/deploy_rest_server/install/scripts
    - env:
      - mysql_ip : {{ pillar['mysql_ip'] }}
      - mysql_port: '{{ pillar['cde_mysql']['mysql_port'] }}'
      - mysql_deploymgrdb_name: {{ pillar['cde_mysql']['deploymgrdb_name'] }}
      - mysql_deploymgrdb_user: {{ pillar['cde_mysql']['deploymgrdb_user'] }}
      - mysql_deploymgrdb_password: {{ pillar['cde_mysql']['deploymgrdb_password'] }}
      - cf_admin_account_password: {{ pillar['deploy_rest_server']['cf_admin_account_password'] }}
      - deploy_os: {{ grains['os'] }}
      - ObjectClass: "Application"

deploy_rest_server-config_copy:
  cmd.run:
    - name: rm -f policybootstrap.tgz
    - cwd: /var/paas/jobs/deploy_rest_server

deploy_rest_server-clean:
  cmd.run:
    - name: rm -rf install
    - cwd: /var/paas/jobs/deploy_rest_server
