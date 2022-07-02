{ config, lib, inventory, secrets, ... }: {
  # Versioning of these providers is provided by Nix.
  terraform.required_providers = {
    cloudflare.source = "cloudflare/cloudflare";
  };

  provider = {
    cloudflare = { };
  };

  resource = {
    cloudflare_zone.personal_zone = {
      zone = inventory.tld;
    };
    cloudflare_record = {
      vpnA = {
        zone_id = "\${cloudflare_zone.personal_zone.id}";
        name = "vpn.${inventory.tld}";
        # This is a placeholder value, as this is obtained via DHCP from the
        # ISP.
        value = "10.10.10.10";
        type = "A";
        proxied = false;
      };
      vpnAAAA = {
        zone_id = "\${cloudflare_zone.personal_zone.id}";
        name = "vpn.${inventory.tld}";
        value = secrets.networking.hurricane.address;
        type = "AAAA";
        proxied = false;
      };
      websiteCNAME = {
        zone_id = "\${cloudflare_zone.personal_zone.id}";
        name = "www.${inventory.tld}";
        value = inventory.tld;
        type = "CNAME";
        proxied = true;
      };
      websiteAAAA = {
        zone_id = "\${cloudflare_zone.personal_zone.id}";
        name = inventory.tld;
        value = inventory.networks.pubwan.hosts.website.ipv6.gua;
        type = "AAAA";
        proxied = true;
      };
    };
  };
}
