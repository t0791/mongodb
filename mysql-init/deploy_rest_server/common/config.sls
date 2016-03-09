deploy_mgr_crontab.conf:
  file.managed:
    - name: /var/paas/jobs/logrotate/crontab.d/deploy_mgr_crontab.conf
    - source: salt://deploy_rest_server/common/files/logrotate/deploy_mgr_crontab.conf
    - makedirs: true
    - mode: 600

deploy_mgr_logrotate.conf:
  file.managed:
    - name: /var/paas/jobs/logrotate/conf/deploy_mgr_logrotate.conf
    - source: salt://deploy_rest_server/common/files/logrotate/deploy_mgr_logrotate.conf
    - makedirs: true
    - mode: 600
