deploy_mgr_logrotate.conf-clean:
  cmd.run:
    - name: rm -rf deploy_mgr_logrotate.conf
    - cwd: /var/paas/jobs/logrotate/conf

deploy_mgr_crontab.conf-clean:
  cmd.run:
    - name: rm -rf deploy_mgr_crontab.conf
    - cwd: /var/paas/jobs/logrotate/crontab.d

deploy_mgr_common_crontab.conf-clean:
  cmd.run:
    - name: rm -rf crontab.conf
    - cwd: /var/paas/jobs/logrotate
