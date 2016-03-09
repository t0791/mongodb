deploy_rest_server-monit-reload:
  cmd.run:
    - name: 'sleep 5 && /var/paas/monit/bin/monit reload'
