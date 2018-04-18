salt_minion_service:
  service.running:
    - name: salt-minion.service
    - watch:
      - file: /etc/salt/minion
