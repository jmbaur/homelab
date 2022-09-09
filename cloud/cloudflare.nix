{ inventory, secrets, ... }: {
  resource = {
    cloudflare_zone.jmbaur_com = {
      zone = "jmbaur.com";
    };
    cloudflare_record = {
      vpnA = {
        zone_id = "\${cloudflare_zone.jmbaur_com.id}";
        name = "vpn.jmbaur.com";
        # This is a placeholder value, as this is obtained via DHCP from the
        # ISP.
        value = "10.10.10.10";
        type = "A";
        proxied = false;
      };
      vpnAAAA = {
        zone_id = "\${cloudflare_zone.jmbaur_com.id}";
        name = "vpn.jmbaur.com";
        value = secrets.networking.hurricane.address;
        type = "AAAA";
        proxied = false;
      };
    };
  };
}
