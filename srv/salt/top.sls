base:
  '*':
     - systemd
     - chronyd
  lxrepo01.devops.test:
     - yum-mirror
     - yum-repo
  lxb00[1-9].devops.test:
     - yum
     - slurm
