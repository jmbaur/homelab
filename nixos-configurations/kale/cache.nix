{ config, ... }: {
  systemd.tmpfiles.rules = [
    "v ${config.services.nginx.virtualHosts."_".root} - ${config.users.users.builder.name} ${config.users.users.builder.group} ~60d -"
  ];

  services.nginx = {
    enable = true;
    commonHttpConfig = ''
      error_log syslog:server=unix:/dev/log;
      access_log syslog:server=unix:/dev/log combined;
    '';
    virtualHosts."_".root = "/var/lib/nix-cache";
  };
}
