inputs:

inputs.nixpkgs.lib.mapAttrs (
  system: pkgs:

  let
    inherit (pkgs) lib;

    inherit (lib)
      getExe
      getExe'
      mapAttrs'
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
        (inputs.nixpkgs.legacyPackages.${system}.nixos {
          imports = [ inputs.self.nixosModules.default ];
          custom.common.enable = true;
          custom.desktop.enable = true;
        }).config.system.build.vm
      )
    );

    updateRepoDependencies = mkApp (
      getExe (
        pkgs.writeShellApplication {
          name = "update-repo-dependencies";
          runtimeInputs = [
            pkgs.jq
            pkgs.nix-prefetch-scripts
          ];
          text =
            # bash
            ''
              NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
              export NIX_PATH

              nix flake update --accept-flake-config

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
                nix develop ".#$(basename "$(dirname "$cargo_toml")")" --command cargo update
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
            pkgs.python3Packages.nix-filter-copy
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
              nix path-info --recursive "$toplevel" >requisites
              nix store sign --stdin --verbose --key-file signing-key <requisites
              nix-filter-copy <requisites | nix copy --verbose --no-recursive --stdin --to "s3://cache?compression=zstd&region=auto&scheme=https&endpoint=''${endpoint}"
              echo -n "$toplevel" | s5cmd --endpoint-url="$endpoint_url" pipe "s3://update/''${name}"
              nix-key sign <(echo -n "$toplevel") signing-key | s5cmd --endpoint-url="$endpoint_url" pipe "s3://update/''${name}.sig"
            fi
          '';
        }
      )
    );

    updateGithubWorkflows =
      let
        ci = (pkgs.formats.yaml { }).generate "ci.yaml" {
          name = "ci";
          on = {
            workflow_dispatch = { }; # allows manual triggering
            push.branches = [ "main" ];
          };
          concurrency = {
            group = "ci-\${{ github.ref }}";
            cancel-in-progress = true; # ensure new jobs take precedence
          };
          # We split out each NixOS machine to being built in its own job so we
          # don't run into the 6-hour max job execution time limit.
          # Anecdotally, one build of the 'celery' machine takes ~3.5
          # hours. The max workflow execution time is 72 hours, which we
          # should definitely be able to fit all our jobs within.
          #
          # TODO(jared): `pkgs.formats.yaml` doesn't handle long lines well.
          jobs =
            {
              test = {
                runs-on = "ubuntu-latest";
                # needed for magic-nix-cache-action
                permissions = {
                  contents = "read";
                  id-token = "write";
                };
                steps = [
                  {
                    name = "Checkout repository";
                    uses = "actions/checkout@v4";
                  }
                  { uses = "DeterminateSystems/nix-installer-action@main"; }
                  { uses = "DeterminateSystems/magic-nix-cache-action@main"; }
                  {
                    name = "Nix flake check";
                    run = ''nix flake check --print-build-logs'';
                  }
                ];
              };
            }
            // mapAttrs' (name: nixosConfig: {
              name = "build-${name}";
              value = {
                needs = [ "test" ];
                runs-on =
                  {
                    x86_64 = "ubuntu-latest";
                    aarch64 = "ubuntu-24.04-arm";
                  }
                  .${nixosConfig._module.args.pkgs.stdenv.buildPlatform.qemuArch};
                # needed for magic-nix-cache-action
                permissions = {
                  contents = "read";
                  id-token = "write";
                };
                steps = [
                  {
                    name = "Checkout repository";
                    uses = "actions/checkout@v4";
                  }
                  {
                    name = "Free Disk Space (Ubuntu)";
                    uses = "jlumbroso/free-disk-space@main";
                    "with".tool-cache = true;
                  }
                  {
                    uses = "DeterminateSystems/nix-installer-action@main";
                    "with".extra-conf = ''
                      extra-substituters = https://cache.jmbaur.com
                      extra-trusted-public-keys = cache.jmbaur.com:C3ku8BNDXgfTO7dNHK+eojm4uy7Gvotwga+EV0cfhPQ=
                    '';
                  }
                  { uses = "DeterminateSystems/magic-nix-cache-action@main"; }
                  {
                    name = "Build ${name}";
                    env = {
                      CACHE_SIGNING_KEY = "\${{ secrets.CACHE_SIGNING_KEY }}";
                      AWS_ACCESS_KEY_ID = "\${{ secrets.AWS_ACCESS_KEY_ID }}";
                      AWS_SECRET_ACCESS_KEY = "\${{ secrets.AWS_SECRET_ACCESS_KEY }}";
                    };
                    run = "nix run .#buildNixosConfigCI -- ${name}";
                  }
                ];
              };
            }) inputs.self.nixosConfigurations;
        };

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
                name = "Update github action workflows";
                run = ''nix run "$PWD#updateGithubWorkflows"'';
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
              echo "# Do not manually edit this file, it is automatically generated" >"$PWD/.github/workflows/ci.yaml"
              tee --append "$PWD/.github/workflows/ci.yaml" <${ci}
              echo "# Do not manually edit this file, it is automatically generated" >"$PWD/.github/workflows/update.yaml"
              tee --append "$PWD/.github/workflows/update.yaml" <${update}
            '';
          }
        )
      );
  }
) inputs.self.legacyPackages
