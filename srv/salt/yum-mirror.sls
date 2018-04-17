/etc/selinux/config:
  file.managed:
    - contents: |
        SELINUX=disabled
        SELINUXTYPE=targeted
firewalld.service:
  service.dead:
    - enable: False
/etc/yum/yum-cron-hourly.conf:
  file.managed:
    - source: salt://yum-mirror/yum-cron-hourly.conf
  pkg.installed:
    - pkgs: 
      - yum-cron
      - yum-utils
  service.running:
    - name: yum-cron.service
    - enable: True
/var/www/html/centos/7/os/x86_64:
  file.directory:
    - makedirs: True
  pkg.installed:
    - name: httpd
  service.running:
    - name: httpd.service
    - enable: true
/etc/systemd/system/reposync.service:
  file.managed:
    - source: salt://yum-mirror/reposync.service
  pkg.installed:
    - name: createrepo
/etc/systemd/system/reposync.timer:
  file.managed:
    - source: salt://yum-mirror/reposync.timer
  service.running:
    - name: reposync.timer
    - enable: True
