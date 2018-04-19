# SaltStack Example

**Build an HPC [Slurm cluster](https://slurm.schedmd.com/) including required infrastructure in virtual machines.**

The shell script ↴ [source_me.sh](source_me.sh) adds the tool-chain in this repository to your shell environment:

```bash
>>> source source_me.sh
# list of nodes
>>> echo $NODES         
lxcm01,lxrepo01,lxdb01,lxfs01,lxrm0[1,2],lxb00[1-4]
```

Make sure to understand how to build development and test environments with **vm-tools**:

<https://github.com/vpenso/vm-tools>

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

Node         | Description
-------------|-------------------------------
lxcm01       | SaltStack master
lxrepo01     | CentOS 7 package mirror & site repo
lxrm0[1,2]   | Slurm master/slave
lxfs01       | NFS Slurm configuration server
lxdb01       | MySQL database
lxb00[1-4]   | Slurm execution nodes

Provision all required virtual machine instances (cf. [clush](https://github.com/vpenso/scripts/blob/master/docs/clush.md)):

```bash
>>> NODES lxcm01,lxrepo01,lxdb01,lxfs01,lxrm0[1,2],lxb00[1-4]
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

```bash
# master configuration files
>>> vm sy lxcm01 -r $SALTSTACK_EXAMPLE/etc/salt/master :/etc/salt/
>>> vm sy lxcm01 -r $SALTSTACK_EXAMPLE/srv/salt :/srv/
# login to the Salt masyer
>>> vm ex lxcm01 -r 
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
salt <target> cmd.run <command> ...     # execute a shell command on nodes
```

Commands used on a **minion**:

```bash
systemctl restart salt-minion           # restart minion
/var/log/salt/minion                    # minion log-file
salt-minion -l debug                    # start minion in forground
```


### Package Mirror & Site Repository


|Nodes    | SLS                                       | Description                                        |
|---------|-------------------------------------------|----------------------------------------------------|
|lxrepo01 | [yum-mirror.sls](srv/salt/yum-mirror.sls) | Configure a CentOS 7 package mirror                |
|         | [yum-repo.sls](srv/salt/yum-repo.sls)     | Configure a package repository for custom RPMs     |

```bash
# confgiure the node
>>> vm ex lxcm01 -r 'salt lxrepo01.devops.test state.apply'
# upload Slurm RPM packages into the repository
>>> vm sy lxrepo01 -r $HOME/projects/centos7_packages/slurm/17.11.3-2/ :/var/www/html/repo/
# rebuild the package repository
>>> vm ex lxrepo01 -r 'createrepo /var/www/html/repo'
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
mysql> grant all on slurm_acct_db.* TO 'slurm'@'localhost' identified by '12345678' with grant option;
mysql> grant all on slurm_acct_db.* TO 'slurm'@'lxrm01' identified by '12345678' with grant option;
mysql> grant all on slurm_acct_db.* TO 'slurm'@'lxrm01.devops.test' identified by '12345678' with grant option;
mysql> grant all on slurm_acct_db.* TO 'slurm'@'lxrm02' identified by '12345678' with grant option;
mysql> grant all on slurm_acct_db.* TO 'slurm'@'lxrm02.devops.test' identified by '12345678' with grant option;
mysql> quit
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
>>> vm ex lxcm01 -r 'salt lxrm0* state.apply'
```

### Slurm Execution Nodes

```bash
# configure the database server
>>> vm ex lxcm01 -r 'salt lxb* state.apply'
```
