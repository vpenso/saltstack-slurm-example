slurm_packages:
  pkg.installed:
    - pkgs:
      - nfs-utils
      - slurm-ohpc
slurm_log_path:
  file.directory:
    - name: /var/log/slurm
    - user: slurm
slurm_conf_path:
  file.directory:
    - name: /etc/slurm
