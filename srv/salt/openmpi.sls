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

openmpi_openhpc_mca_params:
  file.managed:
    - name: /opt/ohpc/pub/mpi/openmpi3-gnu7/3.0.0/etc/openmpi-mca-params.conf
    - source: salt://openmpi/mca-params.conf
