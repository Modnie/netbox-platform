proxmox_node_name     = "pve"
ubuntu_template_vm_id = 9000
netbox_vm = {
  id                  = 300
  name                = "netbox"
  cpu_cores           = 4
  memory_mb           = 8192
  disk_size_gb        = 64
  disk_datastore_id   = "local-lvm"
  bridge              = "vmbr0"
  vlan_id             = 100
  ipv4_address        = "192.0.2.10/24"
  ipv4_gateway        = "192.0.2.1"
  ssh_public_key_file = "~/.ssh/id_ed25519.pub"
}
