slurm_nfs_conf:
  file.managed:
    - name: /etc/systemd/system/etc-slurm.mount
    - source: salt://slurm/etc-slurm.mount
  service.running:
    - name: etc-slurm.mount
    - enable: True
