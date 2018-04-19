slurmd_package:
  pkg.installed:
   - name: slurm-slurmd
slurmd_spool:
  file.directory:
    - name: /var/spool/slurm/d
    - user: slurm
    - makedirs: True
slurmd_firewall:
  file.managed:
    - name: /etc/firewalld/services/slurmd.xml
    - source: salt://slurm/slurmd.xml
  service.running:
    - name: firewalld.service
    - watch:
      - file: /etc/firewalld/services/slurmd.xml
  firewalld.present:
    - name: public
    - services:
      - slurmd
    - prune_services: False
slurmd_service:
  service.running:
    - name: slurmd
    - enable: True
