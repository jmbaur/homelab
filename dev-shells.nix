inputs:
inputs.nixpkgs.lib.mapAttrs (
  system: pkgs:
  let
    inherit (pkgs) lib;

    gpgFingerprint = "D4A0692874AA71B7F1281491BB8667EA7EB08143";

    sopsSupportsAgePlugins = false; # TODO(jared): soon! See https://github.com/getsops/sops/pull/1465
    yubikey5cNfc = "age1yubikey1q20xxhpyk00m3ezajg3769jpmgwkvasq4dzutg75jq96fytnlcmxs9ltmga";
    yubikey5Nfc = "age1yubikey1q0tf5gp52t3smx6zduwyjnurw4cgjlqdm58a9dj6430e8mtrfexfg586p8p";

    sopsConfig = (pkgs.formats.yaml { }).generate "sops.yaml" {
      creation_rules =
        map
          (host: {
            path_regex = "nixos-configurations/${host}/*";
            pgp = lib.concatStringsSep "," [ gpgFingerprint ];
            age = lib.concatStringsSep "," (
              lib.optionals sopsSupportsAgePlugins [
                yubikey5cNfc
                yubikey5Nfc
              ]
              ++ (
                let
                  machinePubkey = lib.fileContents ./nixos-configurations/${host}/age.pubkey;
                in
                lib.optionals (machinePubkey != "") [ machinePubkey ]
              )
            );
          })
          (
            lib.filter (host: builtins.pathExists ./nixos-configurations/${host}/age.pubkey) (
              builtins.attrNames (
                lib.filterAttrs (_: entryType: entryType == "directory") (builtins.readDir ./nixos-configurations)
              )
            )
          );
    };
  in
  {
    default = pkgs.mkShell {
      packages = [
        (pkgs.luajit.withPackages (p: [
          p.cqueues
          p.dkjson
          p.fennel
          p.jeejah
          p.ldbus
          p.shevek
        ]))
        pkgs.chickenPackages_6.chicken
        pkgs.chickenPackages_6.chickenEggs.base64
        pkgs.chickenPackages_6.chickenEggs.libsodium
        pkgs.chickenPackages_6.chickenEggs.simple-logger
        pkgs.chickenPackages_6.chickenEggs.spiffy
        pkgs.chickenPackages_6.chickenEggs.srfi-1
        pkgs.chickenPackages_6.chickenEggs.srfi-13
        pkgs.chickenPackages_6.chickenEggs.srfi-18
        pkgs.chickenPackages_6.chickenEggs.srfi-180
        pkgs.chickenPackages_6.chickenEggs.srfi-37
        pkgs.chickenPackages_6.chickenEggs.vector-lib
        pkgs.home-manager
        pkgs.libsodium
        pkgs.lldb
        pkgs.openscad-unstable
        pkgs.rlwrap
        pkgs.sops
        pkgs.ssh-to-age
        pkgs.zig_0_16
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.chickenPackages_6.chickenEggs.gpiocdev
        pkgs.ubootTools
      ];

      env.SOPS_CONFIG = sopsConfig;

      inherit
        (
          (inputs.git-hooks.lib.${system}.run {
            src = ./.;
            hooks.treefmt = {
              enable = true;
              packageOverrides.treefmt = inputs.self.formatter.${system};
            };
          })
        )
        shellHook
        ;
    };
  }
) inputs.self.legacyPackages
