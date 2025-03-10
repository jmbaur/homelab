inputs:

inputs.nixpkgs.lib.mapAttrs (
  system: pkgs:

  let
    inherit (pkgs) lib;

    inherit (lib)
      getExe
      getExe'
      ;

    mkApp = script: {
      type = "app";
      program = toString script;
    };
  in
  {
    setupPamU2f = mkApp (
      pkgs.writeShellScript "setup-pam-u2f" ''
        ${pkgs.pam_u2f}/bin/pamu2fcfg -opam://homelab
      ''
    );

    setupYubikey = mkApp (
      pkgs.writeShellScript "setup-yubikey" ''
        set -o errexit
        echo "enabling openpgp"
        ${getExe pkgs.yubikey-manager} config usb --enable openpgp
        echo "setting cache for openpgp touches"
        ${getExe pkgs.yubikey-manager} openpgp keys set-touch sig cached-fixed
        echo "changing openpgp pin (default admin pin 12345678, default pin 123456)"
        ${getExe pkgs.yubikey-manager} openpgp access change-admin-pin
        ${getExe pkgs.yubikey-manager} openpgp access change-pin
        echo "enabling fido2"
        ${getExe pkgs.yubikey-manager} config usb --enable fido2
        echo "changing fido2 pin (default pin 123456)"
        ${getExe pkgs.yubikey-manager} fido access change-pin
        echo "adding ssh key backed with fido2"
        ${getExe' pkgs.openssh "ssh-keygen"} -t ed25519-sk -O resident
      ''
    );

    flashKinesis = mkApp (
      pkgs.writeShellScript "flash-kinesis" ''
        ${pkgs.teensy-loader-cli}/bin/teensy-loader-cli -w -v --mcu=TEENSY40 "${pkgs.kinesis-kint41-jmbaur}/kinesis_kint41_jmbaur.hex"
      ''
    );

    testDesktop = mkApp (
      getExe (
        (inputs.nixpkgs.legacyPackages.${system}.nixos (
          { modulesPath, ... }:
          {
            imports = [
              "${modulesPath}/virtualisation/qemu-vm.nix"
              inputs.self.nixosModules.default
            ];
            custom.common.enable = true;
            custom.desktop.enable = true;
            custom.normalUser.username = "waldo";
            virtualisation.cores = 4;
            virtualisation.memorySize = 4096;
            virtualisation.diskSize = 4096;
          }
        )).config.system.build.vm
      )
    );

    updateRepoDependencies = mkApp (
      getExe (
        pkgs.writeShellApplication {
          name = "update-repo-dependencies";
          runtimeInputs = [
            pkgs.all-follow
            pkgs.jq
            pkgs.nix-prefetch-scripts
          ];
          text =
            # bash
            ''
              NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
              export NIX_PATH

              nix flake update
              # auto-follow -i

              readarray -t sources < <(find . -type f -name "*source.json")
              for source in "''${sources[@]}"; do
                args=()
                if [[ $(jq -r ".fetchSubmodules" < "$source") == "true" ]]; then
                  args+=("--fetch-submodules")
                fi
                args+=("$(jq -r ".url" < "$source")")
                nix-prefetch-git "''${args[@]}" | tee "$source"
              done

              # shellcheck disable=SC2185,SC2044
              readarray -t cargo_tomls < <(find ./overlays/pkgs -type f -name "Cargo.toml")
              for cargo_toml in "''${cargo_tomls[@]}"; do
                pushd "$(dirname "$cargo_toml")"
                nix develop ".#$(basename "$(dirname "$cargo_toml")")" --command cargo update --verbose
                popd
              done
            '';
        }
      )
    );

    buildNixosConfigCI = mkApp (
      getExe (
        pkgs.writeShellApplication {
          name = "build-nixos-config-ci";
          runtimeInputs = [
            pkgs.curl
            pkgs.nix-key
            pkgs.s5cmd
          ];
          text = ''
            name=$1

            declare -r endpoint="34455c79130a7a7a9495dc2123622e59.r2.cloudflarestorage.com"
            declare -r endpoint_url="https://''${endpoint}"

            existing_toplevel=$(curl --silent --fail "https://update.jmbaur.com/''${name}" || true)
            toplevel_drv=$(nix eval --raw "$PWD#nixosConfigurations.''${name}.config.system.build.toplevel.drvPath")
            new_toplevel=$(nix derivation show "$toplevel_drv" | jq --raw-output 'to_entries[0].value.outputs.out.path')

            if [[ $new_toplevel == "$existing_toplevel" ]]; then
              echo "NixOS configuration for ''${name} already cached, nothing to do!"
            else
              toplevel=$(nix build --print-build-logs --no-link --print-out-paths "''${toplevel_drv}^out")
              echo -n "$CACHE_SIGNING_KEY" >signing-key
              nix path-info --recursive "$toplevel" | nix store sign --stdin --verbose --key-file signing-key
              nix copy --verbose --to "s3://cache?compression=zstd&region=auto&scheme=https&endpoint=''${endpoint}" "$toplevel"
              echo -n "$toplevel" | s5cmd --endpoint-url="$endpoint_url" pipe "s3://update/''${name}"
              nix-key sign <(echo -n "$toplevel") signing-key | s5cmd --endpoint-url="$endpoint_url" pipe "s3://update/''${name}.sig"
            fi
          '';
        }
      )
    );

    updateGithubWorkflows =
      let
        update = (pkgs.formats.yaml { }).generate "update.yaml" {
          name = "update";
          on = {
            workflow_dispatch = { }; # allows manual triggering
            schedule = [ { cron = "0 3 * * 0"; } ]; # runs weekly on Sunday at 03:00
          };
          jobs.update = {
            runs-on = "ubuntu-latest";
            steps = [
              {
                name = "Checkout repository";
                uses = "actions/checkout@v4";
              }
              {
                name = "Install Nix";
                uses = "DeterminateSystems/nix-installer-action@main";
              }
              {
                name = "Update out of tree packages";
                run = ''nix run "$PWD#updateRepoDependencies"'';
              }
              {
                name = "Create pull request";
                uses = "peter-evans/create-pull-request@v6";
                "with" = {
                  branch = "update-dependencies";
                  delete-branch = true;
                  commit-message = "Update dependencies";
                  title = "Update Dependencies";
                };
              }
            ];
          };
        };
      in
      mkApp (
        getExe (
          pkgs.writeShellApplication {
            name = "update-github-workflows";
            runtimeInputs = [ ];
            text = ''
              echo "# Do not manually edit this file, it is automatically generated" >"$PWD/.github/workflows/update.yaml"
              tee --append "$PWD/.github/workflows/update.yaml" <${update}
            '';
          }
        )
      );
  }
) inputs.self.legacyPackages
