variable "proxmox_node_name" {
  description = "Proxmox VE node on which resources are managed"
  type        = string
}

variable "cloud_image_datastore_id" {
  description = "Proxmox datastore used for cloud images"
  type        = string
}
