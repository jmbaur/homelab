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
          path = with pkgs; [
            gnupg
            semver-tool
          ];
          environment.GNUPGHOME = "/root/.gnupg"; # TODO(jared): sops?
          serviceConfig.StandardInput = "file:/run/build-${name}";
          script = # bash
            ''
              set -o errexit
              set -o nounset
              set -o pipefail

              update_dir=/var/lib/updates/${name}

              output_path=$(cat /dev/stdin)
              if [[ -z "$output_path" ]]; then
                exit 0
              fi

              output_version=$(cat "''${output_path}/version")

              # Don't update anything if we already have the latest
              if [[ -f ''${update_dir}/version ]] && [[ $(semver compare "$output_version" $(cat "''${update_dir}/version")) -eq 0 ]]; then
                exit 0
              fi

              echo "Placing update files for v''${output_version} using output from $output_path"

              find "$update_dir" -mindepth 1 -delete
              cp -rT "$output_path" "$update_dir"
              (cd "$update_dir"; sha256sum * >SHA256SUMS) # SHA256SUMS must be relative to $update_dir
              gpg --batch --yes --sign --detach-sign --output "''${update_dir}/SHA256SUMS.gpg" "''${update_dir}/SHA256SUMS"
            '';
        }
      ) allHosts
    ))
  ];

  # Ensure disk usage doesn't explode. The builder services create symlinks
  # after each successful build, so we should never garbage collect the last
  # successful set of builds.
  nix.gc = {
    automatic = false; # TODO(jared): figure out issues with garbage collection and local-overlay
    dates = "weekly"; # Beginning of the week at midnight
  };

  custom.builder.builds = lib.listToAttrs (
    lib.imap0 (
      i: name:
      lib.nameValuePair name {
        flakeRef = "github:jmbaur/homelab";
        outputAttr = "nixosConfigurations.${name}.config.system.build.image.update";
        postBuild = config.systemd.services."post-build@${name}".name;
        # Daily builds where each build is slated to run in a tiered fashion,
        # one hour after each other.
        #
        # Offset the builds by half-an-hour to ensure they don't collide with
        # nix garbage collection.
        time = "*-*-* ${toString (lib.fixedWidthNumber 2 (i - 24 * (i / 24)))}:30:00";
      }
    ) allHosts
  );
}
