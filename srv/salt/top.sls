base:
  '*':
     - systemd
     - chronyd
     - salt-minion
     - yum
  lxrepo01.devops.test:
     - yum-mirror
     - yum-repo
  lxdb01.devops.test:
     - epel
     - mariadb
     - slurm-db-access
  lxfs01.devops.test:
     - openhpc
     - nfsd
     - users
     - users-home
     - slurm
  lxmon01.devops.test:
     - prometheus
     - prometheus-node-exporter
  lxrm0[1,2].devops.test:
     - openhpc
     - users
     - munge
     - slurm
     - slurm-nfs
     - slurmdbd
     - slurmctld
  lxb00[1-9].devops.test:
     - openhpc
     - users
     - munge
     - slurm
     - slurm-nfs
     - slurmd
     - nfs
