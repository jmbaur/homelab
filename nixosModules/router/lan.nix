{ config, lib, ... }: {
  systemd.network.networks = lib.mapAttrs
    (_: network: {
      name = network.physical.interface; # interface name
      linkConfig = {
        ActivationPolicy = "always-up";
      } // lib.optionalAttrs (network.mtu != null) {
        MTUBytes = toString network.mtu;
      };
      networkConfig = {
        Address = [
          "${network.hosts._router._computed._ipv4Cidr}"
          "${network.hosts._router._computed._ipv6.guaCidr}"
          "${network.hosts._router._computed._ipv6.ulaCidr}"
        ];
        IPv6AcceptRA = false;
      };
    })
    (lib.filterAttrs
      (_: network: network.physical.enable)
      config.router.inventory.networks);
}
