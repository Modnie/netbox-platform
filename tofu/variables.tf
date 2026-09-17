variable "proxmox_node_name" {
  description = "Proxmox VE node on which resources are managed"
  type        = string
}

variable "cloud_image_datastore_id" {
  description = "Proxmox datastore used for cloud images"
  type        = string
}

variable "netbox_vm" {
  description = "NetBox virtual machine configuration"

  type = object({
    id                  = number
    name                = string
    cpu_cores           = number
    memory_mb           = number
    disk_size_gb        = number
    disk_datastore_id   = string
    bridge              = string
    vlan_id             = number
    ipv4_address        = string
    ipv4_gateway        = string
    ssh_public_key_file = string
  })
}
