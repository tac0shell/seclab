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
  default = "hades-win10-ws"
}

locals {
  username          = vault("/hades/data/hades/", "hades_user")
  password          = vault("/hades/data/hades/", "hades_windows_password")
  proxmox_api_id    = vault("/hades/data/hades/", "proxmox_api_id")
  proxmox_api_token = vault("/hades/data/hades/", "proxmox_api_token")
}

variable "proxmox_node" {
  type    = string
  default = "riverstyx"
}

source "proxmox-iso" "seclab-win-ws" {
  proxmox_url  = "https://${var.proxmox_node}:8006/api2/json"
  node         = "${var.proxmox_node}"
  username     = "${local.proxmox_api_id}"
  token        = "${local.proxmox_api_token}"
  iso_file     = "local:iso/win-10-enterprise.iso"
  iso_checksum = "sha256:ef7312733a9f5d7d51cfa04ac497671995674ca5e1058d5164d6028f0938d668"
  /*skip_export             = true*/
  communicator             = "ssh"
  ssh_username             = "${local.username}"
  ssh_password             = "${local.password}"
  ssh_timeout              = "30m"
  qemu_agent               = true
  cores                    = 2
  memory                   = 4096
  vm_name                  = "template-win10-ws"
  template_description     = "Base Seclab Windows Workstation"
  insecure_skip_tls_verify = true

  additional_iso_files {
    device       = "ide3"
    iso_file     = "local:iso/Autounattend-win-10-ws.iso"
    iso_checksum = "sha256:1769ca7704d4eb0a882cb2e8e55d52ca4bbaa70ecd517390614b37c5170b706d"
  }
  additional_iso_files {
    device       = "sata0"
    iso_file     = "local:iso/virtio.iso"
    iso_checksum = "sha256:ebd48258668f7f78e026ed276c28a9d19d83e020ffa080ad69910dc86bbcbcc6"
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
  sources = ["sources.proxmox-iso.seclab-win-ws"]
  provisioner "windows-shell" {
    inline = ["ipconfig"]
  }
}
