mariadb_package:
  pkg.installed:
    - pkgs:
      - mariadb
      - mariadb-server
      - mariadb-libs
mariadb_config:
  file.managed:
    - name: /etc/my.cnf.d/server.cnf
    - makedirs: True
    - contents: |
        [mysqld]
        bind-address=0.0.0.0
  service.running:
    - name: mariadb.service
    - enable: True
    - watch:
      - file: /etc/my.cnf.d/server.cnf
mariadb_firewall:
  firewalld.present:
    - name: public
    - services: 
      - mysql
    - prune_services: False
mariadb_salt_minion_conf:
  file.append:
    - name: /etc/salt/minion
    - text: |
        mysql.host: 'localhost'
        mysql.port: 3306
        mysql.user: 'root'
        mysql.pass: ''
        mysql.db: 'mysql'
        mysql.unix_socket: '/var/lib/mysql/mysql.sock'
        mysql.charset: 'utf8'
  pkg.installed:
    - pkgs:
      - MySQL-python
      - python2-PyMySQL.noarch
