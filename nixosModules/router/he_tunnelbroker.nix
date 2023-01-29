{ config, lib, ... }:
let
  cfg = config.networking.heTunnelBroker;
in
with lib;
{
  options.networking.heTunnelBroker = {
    enable = mkEnableOption "Hurricane Electric TunnelBroker node";
    name = mkOption {
      type = types.str;
      default = "hurricane";
      description = ''
        The name of the SIT netdev.
      '';
    };
    mtu = mkOption {
      type = types.number;
      default = 1480;
      description = ''
        The MTU of the SIT netdev.
      '';
    };
    serverIPv4Address = mkOption {
      type = types.str;
      example = "127.0.0.1";
      description = ''
        The IPv4 address of the tunnel broker server.
      '';
    };
    serverIPv6Address = mkOption {
      type = types.str;
      example = "::1";
      description = ''
        The IPv6 address of the tunnel broker server.
      '';
    };
    clientIPv6Address = mkOption {
      type = types.str;
      example = "::2/64";
      description = ''
        The IPv6 address of the tunnel broker client with the network's prefix.
        NOTE: this option MUST include the ip address ending with a forward
        slash and network prefix.
      '';
    };
  };
  config = mkIf cfg.enable {
    assertions = [{
      message = "Must use systemd-networkd";
      assertion = config.networking.useNetworkd;
    }];
    systemd.network.netdevs.hurricane = {
      tunnelConfig.Remote = cfg.serverIPv4Address;
      netdevConfig = {
        Name = cfg.name;
        Kind = "sit";
        MTUBytes = toString cfg.mtu;
      };
      tunnelConfig = { Local = "any"; TTL = 255; };
    };
    systemd.network.networks.hurricane = {
      name = cfg.name;
      networkConfig = {
        Address = cfg.clientIPv6Address;
        Gateway = cfg.serverIPv6Address;
      };
      linkConfig.RequiredFamilyForOnline = "ipv6";
    };
  };
}
