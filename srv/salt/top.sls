base:
  '*':
     - systemd
     - chronyd
     - salt-minion
  lxrepo01.devops.test:
     - yum-mirror
     - yum-repo
  lxdb01.devops.test:
     - mariadb
     - slurm-db-access
  lxfs01.devops.test:
     - nfsd
  lxrm0[1,2].devops.test:
     - yum
     - slurm
     - slurm-nfs-conf
  lxb00[1-9].devops.test:
     - yum
     - slurm
     - slurm-nfs-conf
