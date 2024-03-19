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
  default = "hades-kali"
}

variable "proxmox_node" {
  type    = string
  default = "riverstyx"
}

locals {
  username          = vault("/hades/data/hades/", "hades_user")
  password          = vault("/hades/data/hades/", "hades_password")
  proxmox_api_id    = vault("/hades/data/hades/", "proxmox_api_id")
  proxmox_api_token = vault("/hades/data/hades/", "proxmox_api_token")
}


source "proxmox-iso" "seclab-kali" {
  proxmox_url              = "https://${var.proxmox_node}:8006/api2/json"
  node                     = "${var.proxmox_node}"
  username                 = "${local.proxmox_api_id}"
  token                    = "${local.proxmox_api_token}"
<<<<<<< HEAD
  iso_file                 = "local:iso/kali-linux-2024.1-installer-amd64.iso"
  iso_checksum             = "sha256:c150608cad5f8ec71608d0713d487a563d9b916a0199b1414b6ba09fce788ced"
=======
  iso_file                 = "local:iso/kali-linux-2023.4-installer-amd64.iso"
  iso_checksum             = "sha256:0b0f5560c21bcc1ee2b1fef2d8e21dca99cc6efa938a47108bbba63bec499779"
>>>>>>> 9bb1a2770249008e568783a5816555503be83d2e
  ssh_username             = "${local.username}"
  ssh_password             = "${local.password}"
  ssh_handshake_attempts   = 100
  ssh_timeout              = "4h"
  http_directory           = "http"
  cores                    = 4
  memory                   = 8192
<<<<<<< HEAD
  vm_name                  = "template-kali-2024.01"
=======
  vm_name                  = "template-kali"
>>>>>>> 9bb1a2770249008e568783a5816555503be83d2e
  qemu_agent               = true
  template_description     = "Kali Linux release 2024.1"
  insecure_skip_tls_verify = true


  network_adapters {
    bridge = "vmbr1"
  }
  network_adapters {
    bridge = "vmbr2"
  }

  disks {
    disk_size    = "50G"
    storage_pool = "proxmox-storage"
  }
  boot_wait = "10s"
  boot_command = [
    "<esc><wait>",
    "/install.amd/vmlinuz noapic ",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kali.preseed ",
    "hostname=hades-kali ",
    "auto=true ",
    "interface=auto ",
    "domain=vm ",
    "initrd=/install.amd/initrd.gz -- <enter>"
  ]
}

build {
  sources = ["sources.proxmox-iso.seclab-kali"]
}
