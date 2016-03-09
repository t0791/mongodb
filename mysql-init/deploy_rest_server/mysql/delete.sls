mysql-stop-scripts:
  file.managed:
    - name: /var/paas/scripts/mysql/scripts/stop.sh
    - source: salt://paas-common/mysql/files/scripts/stop.sh
    - makedirs: true
    - mode: 640

mysql-delete:
  cmd.run:
    - name: '/bin/bash stop.sh'
    - cwd: /var/paas/scripts/mysql/scripts
    - env:
      - mysql_user: '{{ pillar['cde_mysql']['mysql_user'] }}'
      - os: '{{ grains['os'] }}'

mysql-delete-clean:
  cmd.run:
    - name: rm -rf mysql
    - cwd: /var/paas/scripts
