mysql.tgz:
  file.managed:
    - name: /var/paas/packages/mysql.tgz
    - source: salt://package/{{pillar['version']}}/common/mysql.tgz
    - makedirs: true
    - mode: 640

mysql_dependency.tgz:
  file.managed:
    - name: /var/paas/packages/mysql_dependency.tgz
    - source: salt://package/{{pillar['version']}}/common/mysql_dependency.tgz
    - makedirs: true
    - mode: 640