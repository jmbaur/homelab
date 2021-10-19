{ config, pkgs, ... }: {
  networking.dhcpcd = {
    enable = true;
    persistent = true;
    allowInterfaces = [ "enp1s0" ];
    extraConfig = ''
      noipv6rs
      interface enp1s0
        static domain_name_servers=127.0.0.1
        static domain_search=lan
        static domain_name=
    '';
  };
}
