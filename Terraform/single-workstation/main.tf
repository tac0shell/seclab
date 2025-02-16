terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.68.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "4.5.0"
    }
  }
}

variable "proxmox_host" {
  type        = string
  default     = "riverstyx"
  description = "Proxmox node name"
}

variable "hostname" {
  type        = string
  default     = "hades-ws"
  description = "hostname"
}

variable "template_id" {
  type        = string
  description = "Template ID for clone"
}

provider "vault" {

}

data "vault_kv_secret_v2" "hades" {
  mount = "hades"
  name  = "hades"
}

provider "proxmox" {
  # Configuration options
  endpoint  = "https://${var.proxmox_host}:8006/api2/json"
  insecure  = true
  api_token = "${data.vault_kv_secret_v2.hades.data.proxmox_api_id}=${data.vault_kv_secret_v2.hades.data.proxmox_api_token}"
}


resource "proxmox_virtual_environment_vm" "hades-ws" {
  name      = "seclab-workstation"
  node_name = var.proxmox_host
  on_boot   = true

  clone {
    vm_id = var.template_id
    full  = false
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr1"
    model  = "e1000"
  }
  network_device {
    bridge = "vmbr2"
    model  = "e1000"
  }

  connection {
    type            = "ssh"
    user            = data.vault_kv_secret_v2.hades.data.hades_user
    password        = data.vault_kv_secret_v2.hades.data.hades_windows_password
    host            = self.ipv4_addresses[0][0]
    target_platform = "windows"
  }


  provisioner "remote-exec" {
    inline = [
      "powershell.exe -c Rename-Computer '${var.hostname}'",
      "powershell.exe -c Start-Service W32Time",
      "W32tm /resync /force",
      "ipconfig"
    ]
  }

}

output "vm_ip" {
  value       = proxmox_virtual_environment_vm.hades-ws.ipv4_addresses
  sensitive   = false
  description = "VM IP"
}
