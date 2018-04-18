nfsd_package:
  pkg.installed:
    - name: nfs-utils
{% for path in '/etc/slurm','/var/spool/slurm' %}
nfsd_export_path_{{ path }}:
  file.directory:
    - name: {{ path }}
{% endfor %}
nfsd_exports:
  file.managed:
    - name: /etc/exports
    - contents: |
        /etc/slurm lxrm*(rw,sync,no_subtree_check) lx*(ro,sync,no_subtree_check)
        /var/spool/slurm lxrm*(rw,sync)
  service.running:
    - name: nfs-server.service
    - enable: True
    - watch:
      - file: /etc/exports
nfsd_firewall:
  firewalld.present:
    - name: public
    - services:
      - nfs
      - mountd
      - rpc-bind
    - prune_services: False
