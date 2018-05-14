slurmctld_packages:
  pkg.installed:
    - name: ohpc-slurm-server
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
slurmctld_firewall:
  file.managed:
    - name: /etc/firewalld/services/slurmctld.xml
    - source: salt://slurm/slurmctld.xml
  service.running:
    - name: firewalld.service
    - watch:
      - file: /etc/firewalld/services/slurmctld.xml
  firewalld.present:
    - name: public
    - services:
      - slurmctld
    - prune_services: False
slurmctld_service:
  service.running:
    - name: slurmctld.service
    - enable: True
