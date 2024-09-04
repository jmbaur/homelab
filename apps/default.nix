inputs:
inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:
  let
    inherit (pkgs) lib;

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
        ${lib.getExe pkgs.yubikey-manager} config usb --enable openpgp
        echo "setting cache for openpgp touches"
        ${lib.getExe pkgs.yubikey-manager} openpgp keys set-touch sig cached-fixed
        echo "changing openpgp pin (default admin pin 12345678, default pin 123456)"
        ${lib.getExe pkgs.yubikey-manager} openpgp access change-admin-pin
        ${lib.getExe pkgs.yubikey-manager} openpgp access change-pin
        echo "enabling fido2"
        ${lib.getExe pkgs.yubikey-manager} config usb --enable fido2
        echo "changing fido2 pin (default pin 123456)"
        ${lib.getExe pkgs.yubikey-manager} fido access change-pin
        echo "adding ssh key backed with fido2"
        ${lib.getExe' pkgs.openssh "ssh-keygen"} -t ed25519-sk -O resident
      ''
    );

    flashKinesis = mkApp (
      pkgs.writeShellScript "flash-kinesis" ''
        ${pkgs.teensy-loader-cli}/bin/teensy-loader-cli -w -v --mcu=TEENSY40 "${pkgs.kinesis-kint41-jmbaur}/kinesis_kint41_jmbaur.hex"
      ''
    );

    # TODO(jared): Set an expiration date
    generateSysupdateKey = mkApp (
      pkgs.writeShellScript "generate-sysupdate-key" ''
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
        ${lib.getExe' pkgs.gnupg "gpg"} --batch --generate-key sysupdate
        ${lib.getExe' pkgs.gnupg "gpg"} --export jared@update.jmbaur.com -a >pubkey.gpg
        popd
        echo "key generated at $key_dir"
      ''
    );

    updateRepoDependencies = mkApp (
      lib.getExe (
        pkgs.writeShellApplication {
          name = "update-repo-dependencies";
          runtimeInputs = with pkgs; [
            jq
            nix-prefetch-scripts
          ];
          text = ''
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

  }
) inputs.self.legacyPackages
