resource "proxmox_virtual_environment_vm" "netbox" {
  vm_id     = var.netbox_vm.id
  name      = var.netbox_vm.name
  node_name = var.proxmox_node_name

  description   = "NetBox platform managed by OpenTofu"
  tags          = ["netbox", "opentofu"]
  boot_order    = ["scsi0"]
  on_boot       = true
  scsi_hardware = "virtio-scsi-single"

  clone {
    vm_id        = var.ubuntu_template_vm_id
    node_name    = var.proxmox_node_name
    datastore_id = var.netbox_vm.disk_datastore_id
    full         = true
    retries      = 3
  }

  cpu {
    cores = var.netbox_vm.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.netbox_vm.memory_mb
  }

  disk {
    datastore_id = var.netbox_vm.disk_datastore_id
    file_format  = "raw"
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = var.netbox_vm.disk_size_gb
  }

  network_device {
    bridge   = var.netbox_vm.bridge
    firewall = true
    model    = "virtio"
    vlan_id  = var.netbox_vm.vlan_id
  }

  initialization {
    datastore_id = var.netbox_vm.disk_datastore_id
    upgrade      = false

    dns {
      servers = ["8.8.8.8"]
    }

    ip_config {
      ipv4 {
        address = var.netbox_vm.ipv4_address
        gateway = var.netbox_vm.ipv4_gateway
      }
    }

    user_account {
      username = "adminrio"
      keys = [
        trimspace(file(pathexpand(var.netbox_vm.ssh_public_key_file)))
      ]
    }
  }

  serial_device {
    device = "socket"
  }

  operating_system {
    type = "l26"
  }

  started = true
}
