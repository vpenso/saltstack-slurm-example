
function salt-example-upload-state-tree() {
  vm sy lxcm01 -r $SALTSTACK_EXAMPLE/srv/salt :/srv/
}

function salt-example-state-apply() {
  vm ex lxcm01 -r -- salt -t 300 "'$1'" state.apply $2
}
