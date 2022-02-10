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

resource "mikrotik_dns_record" "router_dns_record" {
  name = "router.home.arpa"
  address = "192.168.88.1"
  ttl = 300
}

resource "mikrotik_dns_record" "switch_dns_record" {
  name = "switch.home.arpa"
  address = "192.168.88.2"
  ttl = 300
}

resource "mikrotik_dns_record" "kale_dns_record" {
  name = "kale.home.arpa"
  address = "192.168.88.3"
  ttl = 300
}

resource "mikrotik_dns_record" "asparagus_dns_record" {
  name = "asparagus.home.arpa"
  address = "192.168.88.4"
  ttl = 300
}

resource "mikrotik_dns_record" "rhubarb_dns_record" {
  name = "rhubarb.home.arpa"
  address = "192.168.20.50"
  ttl = 300
}

resource "mikrotik_dns_record" "builder_dns_record" {
  name = "builder.home.arpa"
  address = "192.168.10.19"
  ttl = 300
}

resource "mikrotik_dns_record" "media_dns_record" {
  name = "media.home.arpa"
  address = "192.168.20.29"
  ttl = 300
}
