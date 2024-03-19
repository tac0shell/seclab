terraform {
  required_providers {
    proxmox = {
      source  = "TheGameProfi/proxmox"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.16.0"
    }
  }
}

variable "proxmox_host" {
  type        = string
  default     = "riverstyx"
  description = "description"
}

variable "hostname" {
  type        = string
  default     = "hades-kali"
  description = "description"
}

provider "vault" {

}

data "vault_kv_secret_v2" "hades" {
  mount = "hades"
  name  = "hades"
}

provider "proxmox" {
  # Configuration options
  pm_api_url          = "https://${var.proxmox_host}:8006/api2/json"
  pm_tls_insecure     = true
  pm_log_enable       = true
  pm_api_token_id     = data.vault_kv_secret_v2.hades.data.proxmox_api_id
  pm_api_token_secret = data.vault_kv_secret_v2.hades.data.proxmox_api_token
}


resource "proxmox_vm_qemu" "seclab-kali" {
  cores       = 4
  memory      = 8192
  name        = "hades-kali-2024.01"
  target_node = var.proxmox_host
  clone       = "template-kali-2024.01"
  full_clone  = false
  onboot      = true
  agent       = 1

  connection {
    type     = "ssh"
    user     = data.vault_kv_secret_v2.hades.data.hades_user
    password = data.vault_kv_secret_v2.hades.data.hades_password
    host     = self.default_ipv4_address
  }

  network {
    bridge = "vmbr1"
    model  = "e1000"
  }
  network {
    bridge = "vmbr2"
    model  = "e1000"
  }

  provisioner "remote-exec" {
    inline = [
      "ip a s"
    ]
  }


}

output "vm_ip" {
  value       = proxmox_vm_qemu.seclab-kali.default_ipv4_address
  sensitive   = false
  description = "VM IP"
}
