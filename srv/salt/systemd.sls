systemd-set-timezone:
  file.managed:
    - name: /etc/systemd/system/set-timezone.service
    - source: salt://systemd/set-timezone.service
  service.running:
    - name: set-timezone.service
    - enable: True
systemd-journal-persistent:
  file.managed:
    - name: /etc/systemd/journald.conf.d/journal-storage.conf
    - makedirs: True
    - source: salt://systemd/journal-storage.conf
  service.running:
    - name: systemd-journald.service
    - watch:
      - file: /etc/systemd/journald.conf.d/journal-storage.conf
