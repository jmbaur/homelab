{ lib, pkgs, ... }:
let
  swsPort = 8787;

  allHosts = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../.)
  );
in
{
  custom.wgNetwork.nodes.celery.allowedTCPPorts = [ swsPort ];

  systemd.tmpfiles.settings."10-sws-root"."/var/lib/updates".d = { };

  services.static-web-server = {
    enable = true;
    listen = "[::]:${toString swsPort}";
    root = "/var/lib/updates";
  };

  # Limit the resources available for building, this isn't a super beefy
  # machine :)
  nix.settings = {
    cores = 2;
    max-jobs = 1;
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
        set -x
        while read line; do
          name=$(echo $line | cut -d' ' -f1)
          out=$(echo $line | cut -d' ' -f1)
          for host in ${toString allHosts}; do
            if [[ $name == "$host" ]]; then
              update_dir=/var/lib/updates/$name
              mkdir -p $update_dir
              pushd $update_dir
              cp $out/* .
              sha256sum * >SHA256SUMS
              gpg --batch --sign --detach-sign --output SHA256SUMS.gpg SHA256SUMS
              popd
            fi
          done
        done < /dev/stdin
      '';
    };
  };
}
