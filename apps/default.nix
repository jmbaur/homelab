inputs:

inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:

  let
    inherit (pkgs) lib;

    inherit (lib)
      attrNames
      concatLines
      filterAttrs
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

    ci = mkApp (
      getExe (
        pkgs.writeShellApplication {
          name = "homelab-ci";
          runtimeInputs = [ ];
          text =
            ''
              signing_key=''${1:-}

              if [[ -z $signing_key ]]; then
                echo "no signing key"
                exit 1
              fi
            ''
            + concatLines (
              map
                (
                  name:
                  let
                    substituter = "s3://cache?region=auto&scheme=https&endpoint=34455c79130a7a7a9495dc2123622e59.r2.cloudflarestorage.com";
                  in
                  #bash
                  ''
                    toplevel=$(nix build --print-build-logs --no-link --print-out-paths .#nixosConfigurations.${name}.config.system.build.toplevel)
                    nix-store --query --requisites "$toplevel" >requisites
                    nix store sign --key-file "$signing_key" --verbose <requisites
                    nix copy --to "${substituter}" --stdin --verbose <requisites
                  ''
                )
                (
                  attrNames (
                    filterAttrs (
                      name: _:
                      # Allow-list for machines we want to build in CI.
                      # TODO(jared): Build _all_ of them.
                      (builtins.elem name [ "celery" ])
                    ) inputs.self.nixosConfigurations
                  )
                )
            );
        }
      )
    );
  }
) inputs.self.legacyPackages
