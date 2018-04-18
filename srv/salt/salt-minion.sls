salt_minion_conf:
  file.managed:
    - name: /etc/salt/minion
    - contents: 'master: 10.1.1.7'
salt_minion_service:
  service.running:
    - name: salt-minion.service
    - watch:
      - file: /etc/salt/minion
