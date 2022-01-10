terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.4"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.1.2:8006/api2/json"
}

resource "proxmox_vm_qemu" "dev" {
  name        = "dev"
  target_node = "pve"
  iso   = "local:iso/nixos-custom.iso"
  vmid  = 101
  agent = 1
  cores = 12
  memory = 8192

  network {
    model  = "virtio"
    bridge = "vmbr0"
    firewall = false
  }

  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "100G"
  }
}
