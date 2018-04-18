{% for host in 'localhost','lxrm01','lxrm01.devops.test','lxrm02','lxrm02.devops.test' %}
slurm_db_access_{{host}}:
  mysql_grants.present:
    - database: slurm_acct_db.*
    - user: slurm
    - host: {{ host }}
    - grant: all privileges
    - grant_option: True
{% endfor %}
