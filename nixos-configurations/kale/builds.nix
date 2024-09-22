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

  bucket = "s3://blob9629";
in
{
  sops.secrets = {
    bucket_access_key_id = { };
    bucket_secret_access_key = { };
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
            awscli2
            gnupg
            semver-tool
          ];
          environment.GNUPGHOME = "%S/post-builder/gnupg"; # TODO(jared): use hardware-backed gpg key
          serviceConfig = {
            DynamicUser = true;
            StandardInput = "file:/run/build-${name}";
            StateDirectory = "post-builder";
            LoadCredential = [
              "bucket_access_key_id:${config.sops.secrets.bucket_access_key_id.path}"
              "bucket_secret_access_key:${config.sops.secrets.bucket_secret_access_key.path}"
            ];
          };
          script = ''
            set -o errexit
            set -o nounset
            set -o pipefail

            output_path=$(cat /dev/stdin)
            if [[ -z "$output_path" ]]; then
              echo "No output path found on stdin, nothing to do"
              exit 0
            fi


            export AWS_ACCESS_KEY_ID=$(cat $CREDENTIALS_DIRECTORY/bucket_access_key_id)
            export AWS_SECRET_ACCESS_KEY=$(cat $CREDENTIALS_DIRECTORY/bucket_secret_access_key)

            output_version=$(cat "''${output_path}/version")
            current_version_file=$(mktemp)

            # Don't update anything if we already have the latest
            if aws s3 cp ${bucket}/${name}/version "$current_version_file"; then
              if [[ -f ''${update_dir}/version ]] && [[ $(semver compare "$output_version" $(cat "$current_version_file")) -eq 0 ]]; then
                exit 0
              fi
            fi

            echo "Placing update files for v''${output_version} using output from $output_path"

            cd $(mktemp -d)
            cp -rT "$output_path" .
            sha256sum * >SHA256SUMS
            gpg --batch --yes --sign --detach-sign --output SHA256SUMS.gpg SHA256SUMS

            aws s3 rm --recursive ${bucket}/${name}
            aws s3 cp --recursive . ${bucket}/${name}
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
        attrPath = [
          "nixosConfigurations"
          name
          "config"
          "system"
          "build"
          "image"
        ];
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
