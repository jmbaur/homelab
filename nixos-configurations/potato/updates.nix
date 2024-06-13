{ lib, pkgs, ... }:
let
  swsPort = 8787;

  allHosts = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../.)
  );
in
{
  custom.wgNetwork.nodes.celery.allowedTCPPorts = [ swsPort ];

  services.static-web-server = {
    enable = true;
    listen = "[::]:${toString swsPort}";
    root = "/var/lib/updates";
  };

  custom.builder = {
    builds = lib.listToAttrs (
      lib.imap0 (
        i: name:
        lib.nameValuePair name {
          flakeUri = "github:jmbaur/homelab#nixosConfigurations.${name}.config.system.build.image.update";
          time = "*-*-* ${toString (lib.fixedWidthNumber 2 (i - 24 * (i / 24)))}:00:00";
        }
      ) allHosts
    );

    postBuild = {
      path = [ pkgs.gnupg ];
      environment.GNUPGHOME = "/root/.gnupg"; # TODO(jared): sops?
      script = ''
        while read line; do
          name=$(echo $line | cut -d' ' -f1)
          out=$(echo $line | cut -d' ' -f1)
          for host in ${toString allHosts}; do
            if [[ $name == "$host" ]]; then
              mkdir -p /var/lib/updates/$name
              cp $out/* /var/lib/updates/$name
              gpg --batch --sign --detach-sign --output /var/lib/updates/$name/SHA256SUMS.gpg /var/lib/updates/$name/SHA256SUMS
            fi
          done
        done < /dev/stdin
      '';
    };
  };

  systemd.tmpfiles.settings."10-sws-root"."/var/lib/updates".d = { };
}
