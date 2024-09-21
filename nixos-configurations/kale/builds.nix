{ lib, pkgs, ... }:

let
  allHosts = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../.)
  );
in
{
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
          # TODO(jared): enable this and push updates to a static file server
          enable = false;
          path = with pkgs; [
            gnupg
            semver-tool
          ];
          environment.GNUPGHOME = "/root/.gnupg"; # TODO(jared): sops?
          serviceConfig.StandardInput = "file:/run/build-${name}";
          script = ''
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
    automatic = true;
    dates = "weekly"; # Beginning of the week at midnight
  };

  custom.builder.builds = lib.listToAttrs (
    lib.imap0 (
      i: name:
      lib.nameValuePair name {
        flakeRef = "github:jmbaur/homelab";
        outputAttr = "nixosConfigurations.${name}.config.system.build.image.update";
        postBuild = null; # config.systemd.services."post-build@${name}".name;
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
