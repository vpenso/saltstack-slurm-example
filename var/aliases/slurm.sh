
function salt-example-slurm-config-upload() {
  vm sy lxfs01 -r $SALTSTACK_EXAMPLE/etc/slurm/ :/etc/slurm
}
