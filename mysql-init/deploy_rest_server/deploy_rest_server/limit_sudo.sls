deploy_rest_server-limit-sudo-start:
  cmd.run:
    - name: sudo bash limit_sudo.sh -l
    - cwd: /var/paas/common/limit-sudo
