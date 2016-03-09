deploy_rest_server-archive:
  archive.extracted:
    - name: /var/paas/jobs/deploy_rest_server/
{% if grains['os'] == 'Ubuntu' %}
    - source: salt://package/{{pillar['version']}}/deploy_mgr/deploy-rest-server-Ubuntu.tar.gz
{% elif grains['os'] == 'EulerOS' %}
    - source: salt://package/{{pillar['version']}}/deploy_mgr/deploy-rest-server-euleros.tar.gz
{% endif %}
    - tar_options: v
    - archive_format: tar
    - if_missing: /var/paas/jobs/deploy_rest_server/conf/
    - keep: false

deploy_rest_server-/var/paas/jobs/deploy_rest_server/install/packages:
  file.directory:
    - name: /var/paas/jobs/deploy_rest_server/install/packages
    - makedirs: True
    - mode: 750

deploy_rest_server-/var/paas/sys/log/deploy_rest_server:
  file.directory:
    - name: /var/paas/sys/log/deploy_rest_server
    - makedirs: True
    - mode: 750

deploy_rest_server-/var/paas/sys/run/deploy_rest_server:
  file.directory:
    - name: /var/paas/sys/run/deploy_rest_server
    - makedirs: True
    - mode: 750

deploy_rest_server-scripts:
  file.recurse:
    - name: /var/paas/jobs/deploy_rest_server/install/scripts
    - source: salt://deploy_rest_server/deploy_rest_server/files/scripts
    - include_empty: True
    - file_mode: 640
    - dir_mode: 750

deploy_rest_server-config:
  file.recurse:
    - name: /var/paas/jobs/deploy_rest_server/install/config
    - source: salt://deploy_rest_server/deploy_rest_server/files/config
    - include_empty: True
    - file_mode: 640
    - dir_mode: 750

deploy_rest_server-monitrc:
  file.managed:
    - name: /var/paas/monit/job/deploy_rest_server.monitrc
    - source: salt://deploy_rest_server/deploy_rest_server/files/monit/deploy_rest_server.monitrc
    - template: jinja
    - context: 
      httpaddr: {{ grains['ip4_interfaces']['eth0'][0] }}
      httpport: '{{ pillar['deploy_rest_server']['deploy_rest_server_port'] }}'
    - makedirs: true
    - mode: 640

deploy_rest_server-ctl:
  file.managed:
    - name: /var/paas/jobs/deploy_rest_server/bin/deploy_rest_server_ctl
    - source: salt://deploy_rest_server/deploy_rest_server/files/monit/deploy_rest_server_ctl
    - makedirs: true
    - mode: 700

deploy_rest_server.log:
  file.managed:
    - name: /var/paas/sys/log/deploy_rest_server/deploy_rest_server.log
    - makedirs: True
    - mode: 640

deploy_rest_server_ctl.log:
  file.managed:
    - name: /var/paas/sys/log/deploy_rest_server/deploy_rest_server_ctl.log
    - makedirs: True
    - mode: 640

deploy_rest_server-/var/paas/sys/log/monitPolicyClient:
  file.directory:
    - name: /var/paas/sys/log/monitPolicyClient
    - makedirs: True
    - mode: 750

deploy_rest_server_monitPolicyClient.log:
  file.managed:
    - name: /var/paas/sys/log/monitPolicyClient/monitPolicyClient.log
    - makedirs: True
    - mode: 640
