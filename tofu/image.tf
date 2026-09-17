resource "proxmox_download_file" "ubuntu_noble_cloud_image" {
  content_type = "iso"
  datastore_id = var.cloud_image_datastore_id
  node_name    = var.proxmox_node_name

  file_name = "ubuntu-24.04-server-cloudimg-amd64-20260911.img"
  url       = "https://cloud-images.ubuntu.com/releases/noble/release-20260911/ubuntu-24.04-server-cloudimg-amd64.img"

  checksum           = "612b2c0cc1bc413a6cb8c38fd611794caf0f2b436c50013d8b3794db12ad7354"
  checksum_algorithm = "sha256"
}
