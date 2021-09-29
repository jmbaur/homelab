{ config, pkgs, ... }:

let
  icmp_rules = ''
    ip protocol icmp icmp type {
      echo-request,
      destination-unreachable,
      time-exceeded,
      parameter-problem,
    } counter accept
  '';
in
{
  # Disable these explicitly since we will be handling them with nftables.
  networking.firewall.enable = false;
  networking.nat.enable = false;

  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip filter {
        chain output {
          type filter hook output priority 0
          accept
        }

        chain input {
          type filter hook input priority 0

          # Allow connections from router to come back
          ct state {established,related} accept

          # Drop invalid connections
          ct state invalid drop

          ${icmp_rules}

          # Accept connections from loopback and trusted VLANs
          iifname {lo, mgmt, lab} accept

          iifname {guest, iot} jump input_untrusted

          drop
        }

        chain input_untrusted {
          udp dport 67 udp sport 68 accept
          udp dport 5353 udp sport 5353 accept
          udp dport 53 accept
          drop
        }

        chain forward {
          type filter hook forward priority 0

          # Allow any VLAN access to internet
          iifname {mgmt, lab, guest, iot} oifname {enp1s0} accept

          # Allow main VLAN access to other vlans
          iifname {mgmt} oifname {lab, guest, iot} accept

          # Allow guest VLAN access to iot VLAN
          iifname {guest} oifname {iot} accept

          # Allow Chromecast to talk back to guest VLAN
          iifname {iot} oifname {guest} tcp sport 8009 accept

          # Allow previous connections from internet
          iifname {enp1s0} oifname {mgmt, lab, guest, iot} ct state related,established accept

          ${icmp_rules}

          log prefix "FORWARD rejected: "
          drop
        }
      }

      table ip nat {
        chain prerouting {
          type nat hook prerouting priority 0
          accept
        }

        chain postrouting {
          type nat hook postrouting priority 0
          oifname enp1s0 masquerade
          accept
        }
      }
    '';
  };
}
