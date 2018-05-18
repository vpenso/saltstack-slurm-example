# Open the firewall for OpenMPI communication with
# the port range as define by SrunPortRange in the
# slurm.conf configuration file
openmpi_firewall_rules:
  firewalld.present:
    - name: public
    - ports:
      - 35000-45000/tcp
    - prune_ports: False
    - prune_services: False
