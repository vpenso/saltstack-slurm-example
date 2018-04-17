/etc/yum.repos.d/site.repo:
  file.managed:
    - contents: |
        [site]
        name = site
        baseurl = http://lxrepo01.devops.test/repo
        enabled = 1
        gpgcheck = o
