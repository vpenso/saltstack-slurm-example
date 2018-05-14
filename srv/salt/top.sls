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
     - slurm
     - nfsd
  lxrm0[1,2].devops.test:
     - yum
     - openhpc
     - munge
     - slurm
     - slurm-nfs-conf
     - slurmdbd
     - slurmctld
  lxb00[1-9].devops.test:
     - yum
     - openhpc
     - munge
     - slurm
     - slurm-nfs-conf
     - slurmd
