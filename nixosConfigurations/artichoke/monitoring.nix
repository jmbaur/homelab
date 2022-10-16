{ config, lib, pkgs, inventory, ... }:
let
  blackboxConfig = (pkgs.formats.yaml { }).generate "blackbox-config" {
    modules = {
      icmpv6_connectivity = {
        prober = "icmp";
        timeout = "5s";
        icmp = {
          preferred_ip_protocol = "ip6";
          ip_protocol_fallback = false;
        };
      };
      icmpv4_connectivity = {
        prober = "icmp";
        timeout = "5s";
        icmp = {
          preferred_ip_protocol = "ip4";
          ip_protocol_fallback = false;
        };
      };
    };
  };
in
{
  services.journald.enableHttpGateway = true;
  services.prometheus.exporters = {
    blackbox = {
      enable = false;
      configFile = "${blackboxConfig}";
    };
    node = {
      enable = true;
      enabledCollectors = [ "ethtool" "network_route" "systemd" ];
    };
    wireguard =
      let
        # NOTE: this derivation does not do any actual configuration for
        # wireguard. It just contains peer information so that friendly names
        # can be picked up by the exporter
        stubWireguardConfig = pkgs.writeText "stub-wireguard-config" (lib.concatMapStringsSep "\n"
          (peer: ''
            [Peer]
            # friendly_name = ${peer.name}
            PublicKey = ${peer.publicKey}
            AllowedIPs = ${peer.ipv4},${peer.ipv6.ula}
          '')
          (lib.flatten
            (map
              (name: lib.attrValues inventory.networks.${name}.hosts)
              [ "wg-iot" "wg-trusted" ]
            )
          )
        );
      in
      {
        enable = true;
        wireguardConfig = stubWireguardConfig;
      };
    kea = {
      enable = true;
      controlSocketPaths = [
        config.services.kea.dhcp4.settings.control-socket.socket-name
        config.services.kea.dhcp6.settings.control-socket.socket-name
      ];
    };
  };
  # TODO(jared): remove this when PR https://github.com/NixOS/nixpkgs/pull/195760 is merged
  systemd.services.prometheus-kea-exporter.serviceConfig.ExecStart = lib.mkForce ''
    ${pkgs.prometheus-kea-exporter}/bin/kea-exporter \
      --address ${config.services.prometheus.exporters.kea.listenAddress} \
      --port ${toString config.services.prometheus.exporters.kea.port} \
      ${lib.concatStringsSep " " config.services.prometheus.exporters.kea.controlSocketPaths}
  '';
  nixpkgs.overlays = [
    (_: prev: {
      prometheus-kea-exporter = prev.prometheus-kea-exporter.overrideAttrs
        (_: {
          src = prev.fetchFromGitHub {
            owner = "jmbaur";
            repo = "kea-exporter";
            rev = "16a436969d6e84d57d47130666a064de44c9e159";
            sha256 = "15120dydr4wc99y89jy3k8zk5h7600ax8fhhdp40wd28piwpsmsz";
          };
        });
    })
  ];
}
