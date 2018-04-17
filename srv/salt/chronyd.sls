chronyd:
  pkg.installed:
    - pkgs:
      - chrony
  file.managed:
    - name: /etc/chrony.conf
    - source: salt://chronyd/chrony.conf
  service.running:
    - watch: 
      - file: /etc/chrony.conf
    - enable: True
