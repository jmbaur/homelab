terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.14"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://jared@kale/system"
}

resource "libvirt_volume" "dev" {
  name = "dev.qcow2"
  size = 17179869184
}

resource "libvirt_domain" "dev" {
  name = "dev"
  memory = "4096"
  vcpu = 4
  firmware = "/run/libvirt/nix-ovmf/OVMF_CODE.fd"
  nvram {
    file = "/var/lib/libvirt/qemu/nvram/dev.fd"
    template = "/run/libvirt/nix-ovmf/OVMF_VARS.fd"
  }
  boot_device {
    dev = [ "network", "hd" ]
  }
  disk {
    volume_id = libvirt_volume.dev.id
  }
  network_interface {
    bridge = "br-trusted"
    mac = "52:54:00:62:ad:04"
  }
}
