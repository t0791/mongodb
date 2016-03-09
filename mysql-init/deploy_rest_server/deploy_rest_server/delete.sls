deploy_rest_server-/var/paas/uninstall/deploy_rest_server:
  file.directory:
    - name: /var/paas/uninstall/deploy_rest_server
    - makedirs: True
    - mode: 750

deploy_rest_server-uninstall-scripts:
  file.managed:
    - name: /var/paas/uninstall/deploy_rest_server/delete.sh
    - source: salt://deploy_rest_server/deploy_rest_server/files/scripts/delete.sh
    - makedirs: true
    - mode: 640

deploy_rest_server-uninstall:
  cmd.run:
    - name: '/bin/bash delete.sh'
    - cwd: /var/paas/uninstall/deploy_rest_server

deploy_rest_server-uninstall-clean:
  cmd.run:
    - name: rm -rf uninstall
    - cwd: /var/paas

deploy_rest_server-uninstall-monit_reload:
  cmd.run:
    - name: '/var/paas/monit/bin/monit reload'
