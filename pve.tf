terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.4"
    }
  }
}

provider "proxmox" {
  resource "proxmox_vm_qemu" "test" {
    name        = "test-terraform-vm"
    target_node = "pve"
    iso         = "nixos-minimal-21.11-x86_64-linux.iso"
    vmid        = 102
    agent       = 1

    network = {
      model = "virtio"
      bridge = "vmbr0"
    }

    disk {
      type = "scsi"
      storage = "local-lvm"
      size = "10G"
    }
  }
}
