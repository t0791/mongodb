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
      - mysql_user: '{{ pillar['mysql']['mysql_user'] }}'
      - os: '{{ grains['os'] }}'
{% if pillar['install_mode'] == 'cluster' %}
      - mysql_chroot_dir: '/var/paas/chroot'
{% else %}
      - mysql_chroot_dir: '/var/chroot'
{% endif %}

mysql-delete-clean:
  cmd.run:
    - name: rm -rf mysql
    - cwd: /var/paas/scripts

mysql-mysql_logrotate.conf-clean:
  cmd.run:
    - name: rm -rf mysql_logrotate.conf
    - cwd: /var/paas/jobs/logrotate/conf

mysql-mysql_crontab.conf-clean:
  cmd.run:
    - name: rm -rf mysql_crontab.conf
    - cwd: /var/paas/jobs/logrotate/crontab.d
