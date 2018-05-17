grafana_package:
  pkg.installed:
    - pkgs:
      - grafana

grafana_datasource_prometheus:
  file.managed:
    - name: /etc/grafana/provisioning/datasources/prometheus.yml
    - source: salt://grafana/prometheus.yml

grafana_service:
  service.running:
    - name: grafana-server.service
    - watch:
      - file: /etc/grafana/provisioning/datasources/prometheus.yml

grafana_firewall:
  firewalld.present:
    - name: public
    - ports:
      - 3000/tcp
    - prune_services: False
