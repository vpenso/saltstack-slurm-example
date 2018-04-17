/var/www/html/repo:
  file.directory:
    - makedirs: True
  cmd.run:
    - name: createrepo /var/www/html/repo
    - creates: /var/www/html/repo/repodata
