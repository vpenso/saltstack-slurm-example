slurm_user:
  group.present:
    - name: slurm
    - gid: 123
  user.present:
    - name: slurm
    - fullname: SLURM workload manager
    - uid: 123
    - gid_from_name: True
    - home: /var/lib/slurm
    - shell: /bin/bash
slurm_packages:
  pkg.installed:
    - pkgs:
      - nfs-utils
      - slurm
slurm_log_path:
  file.directory:
    - name: /var/log/slurm
    - user: slurm
slurm_conf_path:
  file.directory:
    - name: /etc/slurm
