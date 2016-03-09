deploy_mgr_common-limit-sudo-rollback:
  cmd.run:
    - name: sudo bash limit_sudo.sh -r
    - cwd: /var/paas/common/limit-sudo
