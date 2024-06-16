{
  config,
  lib,
  pkgs,
  ...
}:
let
  swsPort = 8787;

  allHosts = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../.)
  );
in
{
  custom.wgNetwork.nodes.celery.allowedTCPPorts = [ swsPort ];

  systemd.tmpfiles.settings."10-sws-root" = lib.listToAttrs (
    map (host: lib.nameValuePair "/var/lib/updates/${host}" { d = { }; }) allHosts
  );

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

  systemd.services = lib.mkMerge [
    {
      nix-daemon.serviceConfig = {
        MemoryHigh = "50%";
        MemoryMax = "75%";
      };
    }
    (lib.listToAttrs (
      map (
        name:
        lib.nameValuePair "post-build@${name}" {
          path = [ pkgs.gnupg ];
          environment.GNUPGHOME = "/root/.gnupg"; # TODO(jared): sops?
          serviceConfig.StandardInput = "file:/run/build-${name}";
          script = ''
            output_path=$(cat /dev/stdin)
            if [[ -n "$output_path" ]]; then
              update_dir=/var/lib/updates/${name}
              cp $output_path/* $update_dir
              pushd $update_dir
              rm -f SHA256SUMS SHA256SUMS.gpg; sha256sum * >SHA256SUMS
              gpg --batch --yes --sign --detach-sign --output SHA256SUMS.gpg SHA256SUMS
              popd
            fi
          '';
        }
      ) allHosts
    ))
  ];

  custom.builder.builds = lib.listToAttrs (
    lib.imap0 (
      i: name:
      lib.nameValuePair name {
        flakeUri = "github:jmbaur/homelab#nixosConfigurations.${name}.config.system.build.image.update";
        postBuild = config.systemd.services."post-build@${name}".name;
        # Daily builds where each build is slated to run in a tiered fashion,
        # one hour after each other.
        time = "*-*-* ${toString (lib.fixedWidthNumber 2 (i - 24 * (i / 24)))}:00:00";
      }
    ) allHosts
  );
}
