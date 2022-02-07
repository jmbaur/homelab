terraform {
  required_providers {
    mikrotik = {
      source  = "terraform.local/local/mikrotik"
      version = "1.0.0"
    }
  }
}

provider "mikrotik" {
  host = "192.168.88.1:8728"
}

resource "mikrotik_ip_address" "mgmt_ip" {
  address   = "192.168.88.1/24"
  comment   = "Management LAN router IP address"
  interface = "ether7"
}

resource "mikrotik_ip_address" "trusted_ip" {
  address   = "192.168.10.1/24"
  comment   = "Trusted LAN router IP address"
  interface = "trusted"
}

resource "mikrotik_ip_address" "iot_ip" {
  address   = "192.168.20.1/24"
  comment   = "IOT LAN router IP address"
  interface = "iot"
}

resource "mikrotik_ip_address" "guest_ip" {
  address   = "192.168.30.1/24"
  comment   = "Guest LAN router IP address"
  interface = "guest"
}

resource "mikrotik_pool" "trusted_pool" {
  name    = "trusted_pool"
  ranges  = "192.168.10.100-192.168.10.200"
  comment = "DHCP pool for the Trusted LAN"
}

resource "mikrotik_pool" "iot_pool" {
  name    = "iot_pool"
  ranges  = "192.168.20.100-192.168.20.200"
  comment = "DHCP pool for the IOT LAN"
}

resource "mikrotik_pool" "guest_pool" {
  name    = "guest_pool"
  ranges  = "192.168.10.100-192.168.10.200"
  comment = "DHCP pool for the Guest LAN"
}
