# OpenHPC Slurm Cluster with SaltStack

Component | Description
----------|-------------
CentOS 7  | operating system
SaltStack | orchestration (configuration management)
OpenHPC   | community build HPC packages
Slurm     | workload management system

<https://www.centos.org/>  
<https://docs.saltstack.com/en/latest/>  
<http://www.openhpc.community/>  
<https://slurm.schedmd.com/>

This example uses virtual machines setup with **vm-tools**:

<https://github.com/vpenso/vm-tools>

The shell script ↴ [source_me.sh](source_me.sh) adds the tool-chain in this repository to your shell environment:

```bash
# load the environment
>>> source source_me.sh
# list of required virtual machines
>>> echo $NODES         
lxcm01,lxrepo01,lxdb01,lxfs01,lxrm0[1,2],lxb00[1-4]
```

### Prerequisites

Include the SaltStack package repository to the **CentOS** virtual machine image:

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

List of required virtual machines and services:

Node         | Description
-------------|-------------------------------
lxcm01       | SaltStack master
lxrepo01     | CentOS 7 package mirror & site repo
lxrm0[1,2]   | Slurm master/slave
lxfs01       | NFS Slurm configuration server
lxdb01       | MySQL database
lxb00[1-4]   | Slurm execution nodes

Provision all required virtual machine instances with [vm-tools](https://github.com/vpenso/vm-tools):

```bash
# start new VM instances using `centos7` as source image
>>> vn s centos7
# clean up everything and start from scratch
>>> vn r
```

### Deployment

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

## Configuration

Sync the Salt configuration to the master:

* [srv/salt/](srv/salt/) - The **state tree** includes all SLS (SaLt State file) representing the state in which all nodes should be
* [etc/salt/master](etc/salt/master) - Salt master configuration (`file_roots` defines to location of the state tree)
* [srv/salt/top.sls](srv/salt/top.sls) - Maps nodes to SLS configuration files (cf. [top file](https://docs.saltstack.com/en/latest/ref/states/top.html))

```bash
# master configuration files
>>> vm sy lxcm01 -r $SALTSTACK_EXAMPLE/etc/salt/master :/etc/salt/
>>> vm sy lxcm01 -r $SALTSTACK_EXAMPLE/srv/salt :/srv/
# login to the Salt master
>>> vm lo lxcm01 -r
```

Commands use on the **master**:

```bash
systemctl restart salt-master           # restart the master 
/var/log/salt/master                    # master log-file
salt-key -A -y                          # accept all (unaccpeted) Salt minions
salt-key -d <minion>                    # remove a minion key
salt-key -a <minion>                    # add a single minion key
salt <target> test.ping                 # check if a minion repsonds
salt <target> state.apply               # configure a node
salt <target> state.apply <sls>         # limit configuration to a single SLS file
salt <target> cmd.run <command> ...     # execute a shell command on nodes
```

Commands used on a **minion**:

```bash
systemctl restart salt-minion           # restart minion
journalctl -f -u salt-minion            # read the minion log
salt-minion -l debug                    # start minion in forground
salt-call state.apply <sls>             # limit configuration to a single SLS file
salt-call -l debug state.apply          # debug minion states
```


### Package Mirror & Site Repository


|Nodes    | SLS                                       | Description                                        |
|---------|-------------------------------------------|----------------------------------------------------|
|lxrepo01 | [yum-mirror.sls](srv/salt/yum-mirror.sls) | Configure a CentOS 7 package mirror                |
|         | [yum-repo.sls](srv/salt/yum-repo.sls)     | Configure a package repository for custom RPMs     |

```bash
# confgiure the node
vm ex lxcm01 -r 'salt lxrepo01.devops.test state.apply'
# download release packages for EPEL & OpenHPC
wget https://github.com/openhpc/ohpc/releases/download/v1.3.GA/ohpc-release-1.3-1.el7.x86_64.rpm -P /tmp
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -P /tmp
# upload the release package to the package repository
vm sy lxrepo01 -r -D /tmp/{ohpc,epel}*.rpm :/var/www/html/repo/
# rebuild the package repository
vm ex lxrepo01 -r 'createrepo /var/www/html/repo'
```

Nodes using [yum.sls](srv/salt/yum.sls) will us the site repository.

### SQL Database

Configure `lxdb01` with: 

| Node    | SLS                                      | Description                                        |
|---------|------------------------------------------|----------------------------------------------------|
| lxdb01  | [mariadb.sls](srv/salt/mariadb.sls)      | Configure the MariaDB database server              |
|         | [slurm-db-access.sls](srv/salt/slurm-db-access.sls) | Grant access to the database for Slurm  |

```bash
# configure the database server
>>> vm ex lxcm01 -r 'salt lxdb01* state.apply'
# query the database configuration
>>> vm ex lxcm01 -r 'salt lxdb01* mysql.user_grants slurm lxrm01'
lxdb01.devops.test:
    - GRANT USAGE ON *.* TO 'slurm'@'lxrm01'
    - GRANT ALL PRIVILEGES ON `slurm_acct_db`.`*` TO 'slurm'@'lxrm01' WITH GRANT OPTION
```

Cf. [mysql](https://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.mysql.html) execution module

Unfortunately `slurm-db-access.sls` is not working as expected, you may need to grant access or the slurm user manually:

```bash
>>> vm ex lxdb01 -r mysql
# ..configure ...
grant all on slurm_acct_db.* TO 'slurm'@'localhost' identified by '12345678' with grant option;
grant all on slurm_acct_db.* TO 'slurm'@'lxrm01' identified by '12345678' with grant option;
grant all on slurm_acct_db.* TO 'slurm'@'lxrm01.devops.test' identified by '12345678' with grant option;
grant all on slurm_acct_db.* TO 'slurm'@'lxrm02' identified by '12345678' with grant option;
grant all on slurm_acct_db.* TO 'slurm'@'lxrm02.devops.test' identified by '12345678' with grant option;
quit
```


### NFS Server

Nodes    | SLS                                       | Description
---------|-------------------------------------------|----------------------------------------------------
lxfs01   | [nfsd.sls](srv/salt/nfsd.sls)             | NFS server for the Slurm configuration & state

```bash
# configure the database server
>>> vm ex lxcm01 -r 'salt lxfs01* state.apply'
# check the exports
>>> vm ex lxcm01 -r 'salt lxfs01* cmd.run exportfs'
lxfs01.devops.test:
    /etc/slurm          lxrm*
    /etc/slurm          lx*
    /var/spool/slurm
                lxrm*
# upload the common Slurm configuration to the NFS server
>>> vm sy lxfs01 -r $SALTSTACK_EXAMPLE/etc/slurm/ :/etc/slurm
```

[etc/slurm](etc/slurm) - Slurm cluster configuration files 

### Slurm Workload Manager

| Node       | SLS                                      | Description                                        |
|------------|------------------------------------------|----------------------------------------------------|
| lxrm0[1,2] | [slurmctld.sls](srv/salt/slurmctld.sls)  | Slurm Controller daemon                            |
|            | [slurmdbd.sls](srv/salt/slurmdbd.sls)    | Slurm Database daemon                              |

```bash
# configure the Slurm master and slave 
>>> vm ex lxcm01 -r 'salt lxrm0* state.apply'
# check the service daemons
>>> NODES=lxrm0[1,2] vn ex 'systemctl status slurmctld slurmdbd'
```

Configure the Slurm accounting database:

```bash
# register the new cluster
>>> vm ex lxrm01 -r 'sacctmgr -i add cluster vega'
# start the SLURM cluster controllers
>>> NODES=lxrm0[1,2] vn ex 'systemctl restart slurmctld'
# check the Slurm parition state
>>> vm ex lxrm01 -r 'sinfo'
```

Manage the account DB configuration with the file [accounts.conf](etc/slurm/accounts.conf):

```bash
# load the account configuration
>>> vm sy lxrm01 -r $SALTSTACK_EXAMPLE/etc/slurm/accounts.conf :/tmp
>>> vm ex lxrm01 -r 'sacctmgr --immediate load /tmp/accounts.conf'
```

### Slurm Execution Nodes

| Node       | SLS                                      | Description                                        |
|------------|------------------------------------------|----------------------------------------------------|
| lxb0[1-4]  | [slurmd.sls](srv/salt/slurmd.sls)        | Slurm execution node daemon                        |

```bash
# configure the database server
>>> vm ex lxcm01 -r 'salt lxb* state.apply'
```
