slurmdbd_package:
  pkg.installed:
    - name: ohpc-slurm-server
slurmdbd_firewall:
  file.managed: 
    - name: /etc/firewalld/services/slurmdbd.xml
    - source: salt://slurm/slurmdbd.xml
  service.running:
    - name: firewalld.service
    - watch:
      - file: /etc/firewalld/services/slurmdbd.xml
  firewalld.present:
    - name: public
    - services:
      - slurmdbd
    - prune_services: False
slurmdbd_service:
  service.running:
    - name: slurmdbd.service
    - enable: True
