nfs_path:
  file.directory:
    - name: /nfs
nfs_mount:
  file.managed:
    - name: /etc/systemd/system/nfs.mount
    - source: salt://nfs/nfs.mount
  service.running:
    - name: nfs.mount
    - enable: True
