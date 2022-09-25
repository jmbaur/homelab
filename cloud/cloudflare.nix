{ secrets, ... }: {
  data.http.publicip = {
    url = "https://ipv4.icanhazip.com";
  };

  resource = {
    cloudflare_zone.jmbaur_com = {
      inherit (secrets.cloud.cloudflare) account_id;
      zone = "jmbaur.com";
    };
    cloudflare_record = {
      wwwCNAME = {
        zone_id = "\${cloudflare_zone.jmbaur_com.id}";
        name = "www.jmbaur.com";
        value = "jmbaur.com";
        type = "CNAME";
        proxied = false;
      };
      authCNAME = {
        zone_id = "\${cloudflare_zone.jmbaur_com.id}";
        name = "auth.jmbaur.com";
        value = "jmbaur.com";
        type = "CNAME";
        proxied = false;
      };
      rootAAAA = {
        zone_id = "\${cloudflare_zone.jmbaur_com.id}";
        name = "jmbaur.com";
        value = "\${aws_instance.homelab-web.ipv6_addresses[0]}";
        type = "AAAA";
        proxied = false;
      };
      rootA = {
        zone_id = "\${cloudflare_zone.jmbaur_com.id}";
        name = "jmbaur.com";
        value = "\${aws_instance.homelab-web.public_ip}";
        type = "A";
        proxied = false;
      };
      vpnA = {
        zone_id = "\${cloudflare_zone.jmbaur_com.id}";
        name = "vpn.jmbaur.com";
        value = "\${chomp(data.http.publicip.response_body)}";
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

