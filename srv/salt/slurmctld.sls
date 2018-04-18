slurmctld_spool:
  file.directory:
    - name: /var/lib/slurm/ctld
    - user: slurm
slurmctld_nfs_spool:
  file.managed:
    - name: /etc/systemd/system/var-spool-slurm.mount
    - source: salt://slurm/var-spool-slurm.mount
  service.running:
    - name: var-spool-slurm.mount
    - enable: True
