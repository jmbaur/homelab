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

resource "mikrotik_ip_address" "pubwan_ip" {
  address   = "192.168.10.1/24"
  comment   = "Public WAN router IP address"
  interface = "pubwan"
}

resource "mikrotik_ip_address" "publan_ip" {
  address   = "192.168.20.1/24"
  comment   = "Public LAN router IP address"
  interface = "publan"
}

resource "mikrotik_ip_address" "trusted_ip" {
  address   = "192.168.30.1/24"
  comment   = "Trusted LAN router IP address"
  interface = "trusted"
}

resource "mikrotik_ip_address" "iot_ip" {
  address   = "192.168.40.1/24"
  comment   = "IOT LAN router IP address"
  interface = "iot"
}

resource "mikrotik_ip_address" "guest_ip" {
  address   = "192.168.50.1/24"
  comment   = "Guest LAN router IP address"
  interface = "guest"
}

resource "mikrotik_pool" "trusted_pool" {
  name    = "trusted_pool"
  ranges  = "192.168.30.100-192.168.30.200"
  comment = "DHCP pool for the Trusted LAN"
}

resource "mikrotik_pool" "iot_pool" {
  name    = "iot_pool"
  ranges  = "192.168.40.100-192.168.40.200"
  comment = "DHCP pool for the IOT LAN"
}

resource "mikrotik_pool" "guest_pool" {
  name    = "guest_pool"
  ranges  = "192.168.50.100-192.168.50.200"
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

resource "mikrotik_dns_record" "cap_dns_record" {
  name = "cap.home.arpa"
  address = "192.168.88.5"
  ttl = 300
}

resource "mikrotik_dns_record" "git_dns_record" {
  name = "git.home.arpa"
  address = "192.168.20.21"
  ttl = 300
}

resource "mikrotik_dns_record" "www_dns_record" {
  name = "www.home.arpa"
  address = "192.168.20.11"
  ttl = 300
}

resource "mikrotik_dns_record" "cache_dns_record" {
  name = "cache.home.arpa"
  address = "192.168.20.24"
  ttl = 300
}

resource "mikrotik_dns_record" "rhubarb_dns_record" {
  name = "rhubarb.home.arpa"
  address = "192.168.40.50"
  ttl = 300
}

resource "mikrotik_dns_record" "builder_dns_record" {
  name = "builder.home.arpa"
  address = "192.168.20.23"
  ttl = 300
}

resource "mikrotik_dns_record" "media_dns_record" {
  name = "media.home.arpa"
  address = "192.168.20.29"
  ttl = 300
}

resource "mikrotik_dns_record" "minecraft_dns_record" {
  name = "minecraft.home.arpa"
  address = "192.168.20.32"
  ttl = 300
}
