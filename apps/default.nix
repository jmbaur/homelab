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
        ${pkgs.yubikey-manager}/bin/ykman openpgp keys set-touch sig cached-fixed
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
      pkgs.writeShellScript "update-repo-dependencies" ''
        tmp=$(mktemp)
        export NIX_PATH="nixpkgs=$(nix flake prefetch nixpkgs --json | jq --raw-output '.storePath')"
        nix flake update --accept-flake-config 2>&1 1>&- | tee -a $tmp
        for source in $(find -type f -name "*source.json"); do
          args=()
          if [[ $(jq -r ".fetchSubmodules" < "$source") == "true" ]]; then
            args+=("--fetch-submodules")
          fi
          args+=("$(jq -r ".url" < $source)")
          nix-prefetch-git "''${args[@]}" | tee "$source" | tee -a $tmp
        done
        for cargo_toml in $(find overlays/pkgs -type f -name "Cargo.toml"); do
          pushd $(dirname $cargo_toml)
          nix develop .#$(basename $(dirname $cargo_toml)) --command cargo update
          popd
        done
        echo '```console' > /tmp/pr-body
        ansifilter < $tmp >> /tmp/pr-body
        echo '```' >> /tmp/pr-body
      ''
    );

  }
) inputs.self.legacyPackages
