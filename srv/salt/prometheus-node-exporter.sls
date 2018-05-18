prometheus__node_exporter_package:
  pkg.installed:
    - pkgs:
      - node_exporter

prometheus_node_exporter_service:
  service.running:
    - name: node_exporter.service
    - enable: True

#
# Configure the firewall only if it is running
#
{% if salt['cmd.shell']('firewall-cmd --state') == 'running' %}

prometheus_node_exporter_firewall:
  firewalld.present:
    - name: public
    - ports:
      - 9100/tcp
    - prune_services: False

{% endif %}
