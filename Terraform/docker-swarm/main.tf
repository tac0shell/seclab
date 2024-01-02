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
  default     = "hades-docker-swarm-main"
  description = "description"
}

provider "vault" {

}

data "vault_kv_secret_v2" "seclab" {
  mount = "hades"
  name  = "hades"
}

provider "proxmox" {
  # Configuration options
  pm_api_url          = "https://${var.proxmox_host}:8006/api2/json"
  pm_tls_insecure     = true
  pm_log_enable       = true
  pm_api_token_id     = data.vault_kv_secret_v2.seclab.data.proxmox_api_id
  pm_api_token_secret = data.vault_kv_secret_v2.seclab.data.proxmox_api_token
}


resource "proxmox_vm_qemu" "seclab-docker-swarm-main" {
  cores       = 2
  memory      = 4096
  name        = "docker-main"
  target_node = var.proxmox_host
  clone       = "template-ubuntu-22-04"
  full_clone  = false
  onboot      = true
  agent       = 1

  connection {
    type     = "ssh"
    user     = data.vault_kv_secret_v2.seclab.data.hades_user
    password = data.vault_kv_secret_v2.seclab.data.hades_password
    host     = self.default_ipv4_address
  }

  network {
    bridge = "vmbr1"
    model  = "e1000"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/hades-ubuntu-22-04/hades-docker-swarm-main/g' /etc/hosts",
      "sudo sed -i 's/hades-ubuntu-22-04/hades-docker-swarm-main/g' /etc/hostname",
      "sudo hostname hades-docker-swarm-main",
      "ip a s"
    ]
  }


}

resource "proxmox_vm_qemu" "seclab-docker-swarm-node" {
  cores       = 2
  memory      = 4096
  name        = "Docker-Node"
  target_node = var.proxmox_host
  clone       = "template-ubuntu-22-04"
  full_clone  = false
  onboot      = true
  agent       = 1

  connection {
    type     = "ssh"
    user     = data.vault_kv_secret_v2.seclab.data.hades_user
    password = data.vault_kv_secret_v2.seclab.data.hades_password
    host     = self.default_ipv4_address
  }

  disk {
    type    = "virtio"
    size    = "50G"
    storage = "local-lvm"
  }

  network {
    bridge = "vmbr1"
    model  = "e1000"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/hades-ubuntu-22-04/hades-docker-swarm-node/g' /etc/hosts",
      "sudo sed -i 's/hades-ubuntu-22-04/hades-docker-swarm-node/g' /etc/hostname",
      "sudo hostname hades-docker-swarm-node",
      "ip a s"
    ]
  }


}

output "docker-main-ip" {
  value       = proxmox_vm_qemu.seclab-docker-swarm-main.default_ipv4_address
  sensitive   = false
  description = "Docker Main IP"
}

output "docker-node-ip" {
  value       = proxmox_vm_qemu.seclab-docker-swarm-node.default_ipv4_address
  sensitive   = false
  description = "Docker Node IP"
}
