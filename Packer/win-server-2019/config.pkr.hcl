packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "hostname" {
  type    = string
  default = "hades-win2019-server"
}

variable "proxmox_node" {
  type    = string
  default = "riverstyx"
}


locals {
  username          = vault("/hades/data/hades/", "hades_user")
  password          = vault("/hades/data/hades/", "hades_windows_password")
  proxmox_api_id    = vault("/hades/data/hades/", "proxmox_api_id")
  proxmox_api_token = vault("/hades/data/hades/", "proxmox_api_token")
}


source "proxmox-iso" "seclab-win-server" {
  proxmox_url              = "https://${var.proxmox_node}:8006/api2/json"
  node                     = "${var.proxmox_node}"
  username                 = "${local.proxmox_api_id}"
  token                    = "${local.proxmox_api_token}"
  iso_file                 = "local:iso/win-server-2019.iso"
  iso_checksum             = "sha256:6dae072e7f78f4ccab74a45341de0d6e2d45c39be25f1f5920a2ab4f51d7bcbb"
  insecure_skip_tls_verify = true
  communicator             = "ssh"
  ssh_username             = "${local.username}"
  ssh_password             = "${local.password}"
  ssh_timeout              = "30m"
  qemu_agent               = true
  cores                    = 2
  memory                   = 4096
  vm_name                  = "template-win2019-server"
  template_description     = "Base Seclab Windows Server"

  additional_iso_files {
    device       = "ide3"
    iso_file     = "local:iso/Autounattend-win-server-2019.iso"
    iso_checksum = "sha256:0f8d559c6af317db5d492be42fd0981127a4a05f335059c70fa1b3d23ee6c58a"
    unmount      = true
  }

  additional_iso_files {
    device       = "sata0"
    iso_file     = "local:iso/virtio.iso"
    iso_checksum = "sha256:8a066741ef79d3fb66e536fb6f010ad91269364bd9b8c1ad7f2f5655caf8acd8"
    unmount      = true
  }


  network_adapters {
    bridge = "vmbr2"
  }

  disks {
    type         = "virtio"
    disk_size    = "50G"
    storage_pool = "local-lvm"
  }
  scsi_controller = "virtio-scsi-pci"
}


build {
  sources = ["sources.proxmox-iso.seclab-win-server"]
  provisioner "windows-shell" {
    inline = [
      "ipconfig",
    ]
  }

}
