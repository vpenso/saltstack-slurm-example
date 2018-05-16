base:
  '*':
     - systemd
     - chronyd
     - salt-minion
  lxrepo01.devops.test:
     - yum-mirror
     - yum-repo
  lxdb01.devops.test:
     - yum
     - epel
     - mariadb
     - slurm-db-access
  lxfs01.devops.test:
     - yum
     - openhpc
     - nfsd
     - users
     - users-home
     - slurm
  lxmon01.devops.test:
     - yum
     - prometheus
  lxrm0[1,2].devops.test:
     - yum
     - openhpc
     - users
     - munge
     - slurm
     - slurm-nfs
     - slurmdbd
     - slurmctld
  lxb00[1-9].devops.test:
     - yum
     - openhpc
     - users
     - munge
     - slurm
     - slurm-nfs
     - slurmd
     - nfs
