munge_package:
  pkg.installed:
    - name: munge-ohpc
munge_key:
  file.managed:
    - name: /etc/munge/munge.key
    - source: salt://munge/munge.key
    - show_changes: False
munge_service:
  service.running:
    - name: munge.service
    - watch: 
      - file: /etc/munge/munge.key 
