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
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "8G";
    MemoryMax = "10G";
  };

  systemd.services.post-build = {
    path = [ pkgs.gnupg ];
    environment.GNUPGHOME = "/root/.gnupg"; # TODO(jared): sops?
    script = ''
      set -x
      while true; do
        line=$(cat /dev/stdin)
        name=$(echo $line | cut -d' ' -f1)
        out=$(echo $line | cut -d' ' -f2)
        for host in ${toString allHosts}; do
          if [[ $name == "$host" ]]; then
            update_dir=/var/lib/updates/$name
            mkdir -p $update_dir
            pushd $update_dir
            cp $out/* .
            rm -f SHA256SUMS SHA256SUMS.gpg; sha256sum * >SHA256SUMS
            gpg --batch --yes --sign --detach-sign --output SHA256SUMS.gpg SHA256SUMS
            popd
          fi
        done
      done
    '';
  };

  custom.builder.builds = lib.listToAttrs (
    lib.imap0 (
      i: name:
      lib.nameValuePair name {
        flakeUri = "github:jmbaur/homelab#nixosConfigurations.${name}.config.system.build.image.update";
        time = "*-*-* ${toString (lib.fixedWidthNumber 2 (i - 24 * (i / 24)))}:00:00";
      }
    ) allHosts
  );
}
