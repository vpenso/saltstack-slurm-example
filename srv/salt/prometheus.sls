prometheus_package:
  pkg.installed:
    - pkgs:
      - prometheus2
prometheus_config:
  file.managed:
    - name: /etc/prometheus/prometheus.yml
    - source: salt://prometheus/prometheus.yml
prometheus_service:
  service.running:
    - name: prometheus.service
    - watch:
      - file: /etc/prometheus/prometheus.yml
prometheus_firewall:
  firewalld.present:
    - name: public
    - ports:
      - 9090/tcp
    - prune_services: False
