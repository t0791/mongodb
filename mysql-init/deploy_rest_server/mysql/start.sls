mysql-start-scripts:
  file.managed:
    - name: /var/paas/scripts/mysql/start.sh
    - source: salt://paas-common/mysql/files/scripts/start.sh
    - makedirs: true
    - mode: 640

mysql-start:
  cmd.run:
    - name: '/bin/bash start.sh'
    - cwd: /var/paas/scripts/mysql
    - env:
      - mysql_port: '{{ pillar['cde_mysql']['mysql_port'] }}'
      - mysql_admin_username: '{{ pillar['cde_mysql']['mysql_admin_username'] }}'
      - mysql_admin_password: '{{ pillar['cde_mysql']['mysql_admin_password'] }}'

mysql-start-clean:
  cmd.run:
    - name: rm -rf mysql
    - cwd: /var/paas/scripts
