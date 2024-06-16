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
            curl
            gnupg
            jq
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

              latest_tag=$(curl "https://api.github.com/repos/jmbaur/homelab/tags" | jq -r '.[0].name')
              latest_semver=''${latest_tag#v}

              if [[ -f ''${update_dir}/version ]] && [[ $(semver compare "$latest_semver" $(cat "''${update_dir}/version")) -eq 0 ]]; then
                exit 0
              fi

              if ! [[ $(semver compare "$latest_semver" $(cat "''${output_path}/version")) -eq 0 ]]; then
                exit 0
              fi

              echo "Placing update files for v''${latest_tag} using output from $output_path"

              find "$update_dir" -mindepth 1 -delete
              cp -rT "$output_path" "$update_dir"
              (cd "$update_dir"; sha256sum * >SHA256SUMS) # SHA256SUMS must be relative to $update_dir
              gpg --batch --yes --sign --detach-sign --output "''${update_dir}/SHA256SUMS.gpg" "''${update_dir}/SHA256SUMS"
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
