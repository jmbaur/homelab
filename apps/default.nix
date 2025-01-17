inputs:

inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:

  let
    inherit (pkgs) lib;

    inherit (lib)
      filterAttrs
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

    # TODO(jared): Set an expiration date
    generateSysupdateKey = mkApp (
      pkgs.writeShellScript "generate-sysupdate-key"
        # bash
        ''
          key_dir=$(mktemp -d)
          pushd "$key_dir"
          export GNUPGHOME=$(pwd)
          cat > sysupdate <<EOF
            %echo Generating a sysupdate OpenPGP key
            %no-protection
            Key-Type: EdDSA
            Key-Curve: ed25519
            Name-Real: Jared Baur
            Name-Email: jared@update.jmbaur.com
            Expire-Date: 0
            # Do a commit here, so that we can later print "done"
            %commit
            %echo done
          EOF
          ${getExe' pkgs.gnupg "gpg"} --batch --generate-key sysupdate
          ${getExe' pkgs.gnupg "gpg"} --export jared@update.jmbaur.com -a >pubkey.gpg
          popd
          echo "key generated at $key_dir"
        ''
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

    updateGithubWorkflows =
      let
        ci = (pkgs.formats.yaml { }).generate "ci.yaml" {
          name = "ci";
          on = {
            workflow_dispatch = { }; # allows manual triggering
            push.branches = [ "main" ];
          };
          # We split out each NixOS machine to being built in its own job so we
          # don't run into the 6-hour max job execution time limit.
          # Anecdotally, one build of the 'celery' machine takes ~3.5
          # hours. The max workflow execution time is 72 hours, which we
          # should definitely be able to fit all our jobs within.
          #
          # TODO(jared): Look into concurrent jobs.
          # TODO(jared): `pkgs.formats.yaml` doesn't handle long lines well.
          jobs =
            mapAttrs'
              (name: _: {
                name = "build-${name}";
                value = {
                  runs-on = "ubuntu-latest";
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
                      name = "Install Nix";
                      uses = "DeterminateSystems/nix-installer-action@main";
                      "with".extra-conf = ''
                        extra-substituters = https://cache.jmbaur.com
                        extra-trusted-public-keys = cache.jmbaur.com:C3ku8BNDXgfTO7dNHK+eojm4uy7Gvotwga+EV0cfhPQ=
                      '';
                    }
                    {
                      name = "Build ${name}";
                      env = {
                        CACHE_SIGNING_KEY = "\${{ secrets.CACHE_SIGNING_KEY }}";
                        AWS_ACCESS_KEY_ID = "\${{ secrets.AWS_ACCESS_KEY_ID }}";
                        AWS_SECRET_ACCESS_KEY = "\${{ secrets.AWS_SECRET_ACCESS_KEY }}";
                      };
                      run = ''
                        echo -n "$CACHE_SIGNING_KEY" >signing-key.pem
                        toplevel=$(nix build --print-build-logs --no-link --print-out-paths "$PWD#nixosConfigurations.${name}.config.system.build.toplevel")
                        nix path-info --recursive "$toplevel" | nix store sign --stdin --verbose --key-file signing-key.pem
                        nix copy --verbose --to "s3://cache?compression=zstd&region=auto&scheme=https&endpoint=34455c79130a7a7a9495dc2123622e59.r2.cloudflarestorage.com" "$toplevel"
                      '';
                    }
                  ];
                };
              })
              (
                filterAttrs (
                  name: _:
                  # Allow-list for machines we want to build in CI.
                  # TODO(jared): Build _all_ of them.
                  builtins.elem name [
                    "celery"
                    "squash"
                  ]
                ) inputs.self.nixosConfigurations
              );
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
