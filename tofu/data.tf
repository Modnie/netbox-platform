data "proxmox_version" "current" {}

output "proxmox_version" {
  description = "Proxmox VE version reported by the API"

  value = {
    release       = data.proxmox_version.current.release
    repository_id = data.proxmox_version.current.repository_id
    version       = data.proxmox_version.current.version
  }
}
