# OpenHPC Slurm Cluster with SaltStack

Build a HPC Cluster using the following infrastructure components:

Component  | Description                   | Cf.
-----------|-------------------------------|-----------------------
CentOS 7   | Operating system              | <https://www.centos.org/>
SaltStack  | Infrastructure orchestration  | <https://saltstack.com/>
EPEL       | Fedora community packages     | <https://fedoraproject.org/wiki/EPEL>
OpenHPC    | Community HPC packages        | <http://www.openhpc.community/>
MariaDB    | Relational database           | <https://mariadb.org/>
Slurm      | Workload management system    | <https://slurm.schedmd.com/>
Prometheus | Time-series database          | <https://prometheus.io/>
Grafana    | Monitoring dashboard          | <https://grafana.com/>

This example uses virtual machines setup with **vm-tools**:

<https://github.com/vpenso/vm-tools>

The shell script ↴ [source_me.sh](source_me.sh) adds the tool-chain in this repository to your shell environment:

```bash
# load the environment
>>> source source_me.sh 
NODES=lxcm01,lxrepo01,lxdb01,lxfs01,lxmon01,lxrm0[1,2],lxb00[1-4]
```

### Prerequisites

List of required virtual machines and services:

Node         | Description
-------------|-------------------------------
lxcm01       | SaltStack master
lxrepo01     | CentOS 7 package mirror & site repo
lxrm0[1,2]   | Slurm master/slave
lxfs01       | NFS Slurm configuration server
lxdb01       | MySQL database
lxmon01      | Prometheus monitoring server
lxb00[1-4]   | Slurm execution nodes

Make sure that the [SaltStack package repository][spr] is included in the **CentOS** virtual machine image:

[spr]: https://docs.saltstack.com/en/latest/topics/installation/rhel.html

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

Alternatively copy the repo configuration to all VMs after start:

```bash
vn sy -r $SALTSTACK_EXAMPLE/etc/yum.repos.d/salt.repo :/etc/yum.repos.d/salt.repo
```

Provision all required virtual machine instances

```bash
# start new VM instances using `centos7` as source image
>>> vn s centos7
# clean up everything and start from scratch
>>> vn r
```

### Deployment

Install Saltstack on all nodes (cf. [Salt configuration](https://docs.saltstack.com/en/latest/ref/configuration/index.html)):

```bash
# install the SaltStack master
>>> vm ex lxcm01 -r '
  yum install -y salt-master;
  firewall-cmd --permanent --zone=public --add-port=4505-4506/tcp;
  firewall-cmd --reload;
  systemctl enable --now salt-master && systemctl status salt-master
'
# install the SaltStack minions on all nodes
>>> vn ex -r '
  yum install -y salt-minion;
  echo "master: 10.1.1.7" > /etc/salt/minion;
  systemctl enable --now salt-minion && systemctl status salt-minion
'
```

## Configuration

Sync the Salt configuration to the master:

* [srv/salt/](srv/salt/) - The **state tree** includes all SLS (SaLt State file) representing the state in which all nodes should be
* [etc/salt/master](etc/salt/master) - Salt master configuration (`file_roots` defines to location of the state tree)
* [srv/salt/top.sls](srv/salt/top.sls) - Maps nodes to SLS configuration files (cf. [top file](https://docs.saltstack.com/en/latest/ref/states/top.html))

```bash
# upload the salt-master service configuration files
vm sy lxcm01 -r $SALTSTACK_EXAMPLE/etc/salt/master :/etc/salt/
# upload the salt configuration reposiotry
vm sy lxcm01 -r $SALTSTACK_EXAMPLE/srv/salt :/srv/
# accept all Salt minions
vm ex lxcm01 -r 'systemctl restart salt-master ; salt-key -A -y'
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
salt-run jobs.active                    # list active jobs
salt-run jobs.exit_success <jid>        # check if a job has finished
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


| Nodes    | SLS                                       | Description                                        |
|----------|-------------------------------------------|----------------------------------------------------|
| lxrepo01 | [yum-mirror.sls](srv/salt/yum-mirror.sls) | Configure a CentOS 7 package mirror                |
| lxrepo01 | [yum-repo.sls](srv/salt/yum-repo.sls)     | Configure a package repository for custom RPMs     |
| *        | [yum.sls](srv/salt/yum.sls)               | Nodes using the local mirror & repo
```bash
# configure the node
vm ex lxcm01 -r 'salt lxrepo01.devops.test state.apply'
# download release packages for EPEL & OpenHPC
wget https://github.com/openhpc/ohpc/releases/download/v1.3.GA/ohpc-release-1.3-1.el7.x86_64.rpm -P /tmp
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -P /tmp
# upload the release package to the package repository
vm sy lxrepo01 -r -D /tmp/{ohpc,epel}*.rpm :/var/www/html/repo/
# rebuild the package repository
vm ex lxrepo01 -r 'createrepo /var/www/html/repo'
```

```bash
# show the local package mirror & repo with your default web-browser
for url in centos repo ; do $BROWSER http://$(virsh-nat-bridge lo lxrepo01 | cut -d' ' -f2)/$url ; done
```

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


### NFS Storage

NFS server configuration:

Nodes    | SLS                                       | Description
---------|-------------------------------------------|----------------------------------------------------
lxfs01   | [nfsd.sls](srv/salt/nfsd.sls)             | NFS server for the Slurm configuration & state

```bash
# configure the NFS server
>>> vm ex lxcm01 -r -- salt -t 120 lxfs01\* state.apply
# check the exports
>>> vm ex lxcm01 -r salt lxfs\* cmd.run exportfs  
lxfs01.devops.test:
    /etc/slurm          lxrm*
    /etc/slurm          lx*
    /var/spool/slurm
                lxrm*
    /nfs                lx*
# or using a Salt execution module
>>> vm ex lxcm01 -r salt 'lxfs*' nfs3.list_exports
```

Slurm cluster configuration files in [etc/slurm](etc/slurm)

```bash
# upload the common Slurm configuration to the NFS server
vm sy lxfs01 -r $SALTSTACK_EXAMPLE/etc/slurm/ :/etc/slurm
```

NFS client configuration:

Node                  | SLS                                      | Path             | Description
----------------------|------------------------------------------|------------------|-------------------------------
lxb00[1-4],lxrm0[1,2] | [slurm-nfs.sls](srv/salt/slurm-nfs.sls)  | /etc/slurm       | Slurm configuration
lxrm0[1,2]            |                                          | /var/spool/slurm | Slurm controller state (master/slave)
lxb00[1-4]            | [nfs.sls](srv/salt/nfs.sls)              | /nfs             | Shared cluster storage

```bash
# list all required mounts in the infrastructure 
vm ex lxcm01 -r -- salt "'*'" mount.active | grep -e lx -e slurm -e nfs
```


### Workload Manager

Slurm **Controller** (master/slave) configuration; 

| Node       | SLS                                      | Description                                        |
|------------|------------------------------------------|----------------------------------------------------|
| lxrm0[1,2] | [slurmctld.sls](srv/salt/slurmctld.sls)  | Slurm Controller daemon                            |
|            | [slurmdbd.sls](srv/salt/slurmdbd.sls)    | Slurm Database daemon                              |

```bash
# configure the Slurm master and slave 
vm ex lxcm01 -r -- salt -t 300 'lxrm*' state.apply
# check the service daemons with expression matching
vm ex lxcm01 -r -- salt -E "'lx(rm|b)'" service.status 'slurm*'
```

Configure the Slurm accounting database:

```bash
# register the new cluster
vm ex lxrm01 -r -- sacctmgr -i add cluster vega
# restart the SLURM cluster controllers
vm ex lxcm01 -r salt 'lxrm*' service.restart slurmctld
# check the Slurm parition state
vm ex lxrm01 -r sinfo
```

Manage the account DB configuration with the file [etc/slurm/accounts.conf](etc/slurm/accounts.conf):

```bash
# load the account configuration
vm sy lxrm01 -r $SALTSTACK_EXAMPLE/etc/slurm/accounts.conf :/tmp
vm ex lxrm01 -r -- sacctmgr --immediate load /tmp/accounts.conf
```

Slurm **executuion nodes** configuration:

| Node       | SLS                                      | Description                                        |
|------------|------------------------------------------|----------------------------------------------------|
| lxb0[1-4]  | [slurmd.sls](srv/salt/slurmd.sls)        | Slurm execution node daemon                        |

```bash
# configure all Slurm execution nodes
vm ex lxcm01 -r -- salt -t 300 -E lxb state.apply
```

Install user application software (cf. [Salt Job Management](https://docs.saltstack.com/en/latest/topics/jobs/index.html)):

```bash
# login to the salt master
vm lo lxcm01 -r
# span a job to install packages required for user applications
jid=$(salt --async 'lxb*' state.apply users-packages | cut -d: -f2) && echo $jid
# list running jobs
salt-run jobs.active
# show the corresponding job
salt-run jobs.print_job $jid
# check if the job has finished successful
salt-run jobs.exit_success $jid
# kill the job on the nodes...
salt 'lxb*' saltutil.kill_job $jid
```

### Monitoring

RPM packages are provided by [Packagecloud](https://packagecloud.io/):

<https://github.com/lest/prometheus-rpm>  
<https://packagecloud.io/prometheus-rpm>

```bash
# download the packages from packagecloud
wget --content-disposition https://packagecloud.io/prometheus-rpm/release/packages/el/7/prometheus2-2.2.1-1.el7.centos.x86_64.rpm/download.rpm -P /tmp
wget --content-disposition https://packagecloud.io/prometheus-rpm/release/packages/el/7/node_exporter-0.15.2-1.el7.centos.x86_64.rpm/download.rpm -P /tmp
wget --content-disposition https://packagecloud.io/grafana/stable/packages/el/6/grafana-5.1.3-1.x86_64.rpm/download.rpm -P /tmp
# upload the packages to the local repository
vm sy lxrepo01 -r -D /tmp/{prom,node,graf}*.rpm :/var/www/html/repo/
vm ex lxrepo01 -r createrepo /var/www/html/repo
```

**Prometheus** configuration:

 Node     | SLS                                       | Description
----------|-------------------------------------------|--------------------------------
 lxmon01  | [prometheus.sls](srv/salt/prometheus.sls) | Prometheus server configuration
 ~        | [prometheus-node-exporter.sls](srv/salt/prometheus-node-exporter.sls) | Nodes expose monitoring metrics with `node-expoerter`

```bash
# configure the Prometheus server 
vm ex lxcm01 -r salt 'lxmon*' state.apply
# open the Prometheus metrics page in your default browser
$BROWSER http://$(vm ip lxmon01):9090/metrics
# check the state of nodes defined in for scraping metrics
$BROWSER http://$(vm ip lxmon01):9090/targets
```

The Prometheus server configuration: [prometheus.yml](srv/salt/prometheus/prometheus.yml) (cf. [Prometheus Configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/))

```bash
# deploy the node-exporter on all nodes
vm ex lxcm01 -r -- salt -t 120 -C "'* and not L@lxcm01.devops.test'" state.apply prometheus-node-exporter
```

**Grafana** configuration:

 Node     | SLS                                       | Description
----------|-------------------------------------------|--------------------------------
 lxmon01  | [grafana.sls](srv/salt/grafana.sls)       | Prometheus server configuration

```bash
# open the Grafana web-interface in your default browser
$BROWSER http://$(vm ip lxmon01):3000
# default user/password: admin/admin
```

Cf. [Grafana Configuration](http://docs.grafana.org/installation/configuration/):

* Prometheus is configured as data-source with [prometheus.yml](srv/salt/grafana/prometheus.yml)
* Import one of the node exporter dashboards, i.e. ID:[1860](https://grafana.com/dashboards/1860)

## Usage

Depending on the test the virtual machine resource can be adjusted

```bash
# reconfigure the libvirt VM instance configuration, i.e. 2GB RAM, 2 CPUs and VNC support
NODES='lxb00[1-4]' vn co -M 2 -c 2 -vO
# shutdown, undefine, define, start VM instances
NODES='lxb00[1-4]' vn rd
```

Configuring OpenMPI with a firewall is still an issue:

```bash
# switch of the firewall on execution nodes
>>> vm ex lxcm01 -r -- salt -E lxb service.stop firewalld
# Slurm port range Configuration
>>> vm ex lxrm01 -- scontrol show config | grep -i srun
SrunEpilog              = (null)
SrunPortRange           = 35000-45000
SrunProlog              = (null)

```

Run an example MPI application

```bash
# login as a user to an execution node
vm lo lxb001 -r -- su - sulu
# list MPI environments
srun --mpi=list
# compile a sample MPI program
mpicc -O3 /opt/ohpc/pub/examples/mpi/hello.c -o hello
# allocate two nodes
salloc -N 2 /bin/bash
# run the MPI application
srun --mpi pmix hello
# or 
prun hello
```
