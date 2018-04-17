### Prerequisites

Make sure to understand how to build development and test environments with virtual machines:

<https://github.com/vpenso/vm-tools>

Include the SaltStack package repository to the CentOS virtual machine image:

<https://docs.saltstack.com/en/latest/topics/installation/rhel.html>

```bash
>>> cat /etc/yum.repos.d/salt.repo
[saltstack-repo]
name=SaltStack repo for Red Hat Enterprise Linux $releasever
baseurl=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/latest
enabled=1
gpgcheck=1
gpgkey=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/latest/SALTSTACK-GPG-KEY.pub
       https://repo.saltstack.com/yum/redhat/$releasever/$basearch/latest/base/RPM-GPG-KEY-CentOS-7
```

Node         | Description
-------------|-------------------------------
lxcm01       | SaltStack master
lxrepo01     | CentOS 7 package mirror & site repo
lxrm0[1,2]   | Slurm master/slave
lxdb01       | MySQL database
lxb00[1-4]   | Slurm execution nodes

Start all required virtual machine instances (cf. [clush](https://github.com/vpenso/scripts/blob/master/docs/clush.md)):

```bash
>>> NODES lxcm01,lxrepo01,lxdb01,lxrm0[1,2],lxb00[1-4]
# start new VM instances using `centos7` as source image
>>> vn s centos7
# clean up everything and start from scratch
>>> vn r
```


### SaltStack Deployment

Install Saltstack on all nodes:

Cf. <https://docs.saltstack.com/en/latest/ref/configuration/index.html>

```bash
# install the SaltStack master
>>> vm ex lxcm01 -r '
  yum install -y salt-master;
  firewall-cmd --permanent --zone=public --add-port=4505-4506/tcp;
  firewall-cmd --reload;
  systemctl start salt-master && systemctl  status salt-master
'
# install the SaltStack minions on all nodes
>>> vn ex '
  yum install -y salt-minion;
  echo "master: 10.1.1.7" > /etc/salt/minion;
  systemctl start salt-minion && systemctl status salt-minion
'
```

## Usage

Sync the Salt configuration to the master:

* [srv/salt/](srv/salt/) - The **state tree** includes all SLS (SaLt State file) representing the state in which all nodes should be
* [etc/salt/master](etc/salt/master) - Salt master configuration (`file_roots` defines to location of the state tree)

```bash
# master configuration files
>>> vm sy lxcm01 -r $SALTSTACK_EXAMPLE/etc/salt/master :/etc/salt/
>>> vm sy lxcm01 -r $SALTSTACK_EXAMPLE/srv/salt :/srv/
# login to the Salt masyer
>>> vm ex lxcm01 -r 
```

Following a list of commands use on the master:

```bash
systemctl restart salt-master           # restart the master 
salt-key -A -y                          # accept all (unaccpeted) Salt minions
salt <target> state.apply               # configure a node
```


### Package Mirror & Site Repository

Configure `lxrepo01` with [yum-mirror.sls](srv/salt/yum-mirror.sls) and [yum-repo.sls](srv/salt/yum-repo.sls):

```bash
# confgiure the node
>>> vm ex lxcm01 -r 'salt lxrepo01.devops.test state.apply'
# upload Slurm RPM packages into the repository
>>> vm sy lxrepo01 -r $HOME/projects/centos7_packages/slurm/17.11.3-2/ :/var/www/html/repo/
# rebuild the package repository
>>> vm ex lxrepo01 -r 'createrepo /var/www/html/repo'
```
