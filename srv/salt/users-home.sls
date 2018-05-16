{% for user in 'spock','kirk','sulu','uhura' %}
users_home_/nfs/{{ user }}:
  file.directory:
    - name: /nfs/{{ user }}
    - user: {{ user }}
{% endfor %}
