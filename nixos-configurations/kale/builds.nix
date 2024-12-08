{
  config,
  lib,
  pkgs,
  ...
}:

let
  allHosts = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../.)
  );
in
{
  sops.secrets.rclone_config = { };
  sops.secrets.sysupdate_gnupg = {
    sopsFile = "/etc/sysupdate-gnupg.json";
    format = "binary";
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
            rclone
            semver-tool
            unzip
          ];
          serviceConfig = {
            DynamicUser = true;
            StandardInput = "file:/run/build-${name}";
            LoadCredential = [
              "rclone_config:${config.sops.secrets.rclone_config.path}"
              "signing_key_zip:${config.sops.secrets.sysupdate_gnupg.path}"
            ];
          };
          script = ''
            set -o errexit
            set -o nounset
            set -o pipefail

            export GNUPGHOME=$(mktemp -d)
            unzip $CREDENTIALS_DIRECTORY/signing_key_zip -d "$GNUPGHOME"

            output_path=$(cat /dev/stdin)
            if [[ -z "$output_path" ]]; then
              echo "No output path found on stdin, nothing to do"
              exit 0
            fi

            output_version=$(cat "''${output_path}/version")
            current_version=$(rclone --config $CREDENTIALS_DIRECTORY/rclone_config cat r2:update/${name}/version || echo 0.0.0)

            if [[ -n "$current_version" ]] && [[ $(semver compare "$output_version" "$current_version") -eq 0 ]]; then
              echo "Don't have anything to update, we already have to latest"
              exit 0
            fi

            echo "Placing update files for v''${output_version} using output from $output_path"

            cd $(mktemp -d)
            cp -rT "$output_path" .
            sha256sum * >SHA256SUMS
            gpg --batch --yes --sign --detach-sign --output SHA256SUMS.gpg SHA256SUMS

            rclone --config $CREDENTIALS_DIRECTORY/rclone_config delete r2:update/${name}
            rclone --config $CREDENTIALS_DIRECTORY/rclone_config copy . r2:update/${name} --progress
          '';
        }
      ) allHosts
    ))
  ];

  # TODO(jared): this is needed for now with the builder module
  custom.image.mutableNixStore = true;

  custom.builder.builds = lib.listToAttrs (
    lib.imap0 (
      i: name:
      lib.nameValuePair name {
        postBuild = config.systemd.services."post-build@${name}".name;
        # Daily builds where each build is slated to run in a tiered fashion,
        # one hour after each other.
        time = "*-*-* ${toString (lib.fixedWidthNumber 2 (i - 24 * (i / 24)))}:00:00";
        build = {
          flake = {
            flakeRef = "github:jmbaur/homelab";
            attrPath = [
              "nixosConfigurations"
              name
              "config"
              "system"
              "build"
              "image"
            ];
          };
        };
      }
    ) allHosts
  );
}
