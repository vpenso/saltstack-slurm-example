

Include the SaltStack package repository to the CentOS virtual machine [image](image.md):

Cf. <https://docs.saltstack.com/en/latest/topics/installation/rhel.html>

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

Start a group of virtual machine [instances](instance.md) and install a master and a couple of minions:

```bash
>>> NODES lxcm01,lxdev0[1-4]
# start all VM instances
>>> vn s centos7
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



### Usage

Sync the Salt configuration to the master:

```bash
# master configuration file
>>> vm sy lxcm01 -r $SALTSTACK_EXAMPLE/etc/salt/master :/etc/salt/
# 
>>> vm sy lxcm01 -r $SALTSTACK_EXAMPLE/srv/salt :/srv/
# accept the keys of all minions
>>> vm ex lxcm01 -r 'salt-key -A -y'
# apply the configuration to all nodes
>>> vm ex lxcm01 -r 'salt '*' state.apply'
```

