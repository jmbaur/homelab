# Requirements

- You must use nftables for extra firewall configuration. The firewall built by
  this module uses nftables, so loading the iptables kernel modules will
  conflict with the nftables kernel module.

# Assumptions

This is a highly opinionated nixos module, so there are some assumptions that
currently fit best with my setup. They are as follows:

- Your ISP does not support IPv6
- You use Hurricane Electric's tunnelbroker service to get IPv6 support
- Your internal IPv4 network(s) are a /24
- You have a global unicast (GUA) /48 IPv6 network prefix
- You generated a unique local (ULA) /48 IPv6 network prefix
