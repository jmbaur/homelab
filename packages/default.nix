inputs: with inputs;
let
  common_installer_modules = [
    self.nixosModules.default
    { custom.installer.enable = true; }
  ];

  installer_iso_modules = common_installer_modules ++ [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  commonDerivations = pkgs: {
    inherit (pkgs)
      grafana-dashboards
      jmbaur-github-ssh-keys
      jmbaur-keybase-pgp-keys
      ;

    installer_iso = (nixpkgs.lib.nixosSystem {
      inherit (pkgs) system;
      modules = installer_iso_modules;
    }).config.system.build.isoImage;

    crs_305 = pkgs.callPackage ./routeros/crs305/configuration.nix {
      inventoryFile = self.packages.${pkgs.system}.inventory;
    };

    crs_326 = pkgs.callPackage ./routeros/crs326/configuration.nix {
      inventoryFile = self.packages.${pkgs.system}.inventory;
    };

    cap_ac = pkgs.callPackage ./routeros/capac/secretsWrapper.nix {
      inventoryFile = self.packages.${pkgs.system}.inventory;
      configurationFile = ./routeros/capac/configuration.nix;
    };

    inventory = pkgs.writeText "inventory.json" (builtins.toJSON (self.inventory.${pkgs.system}.inventory));

    tf-config = terranix.lib.terranixConfiguration rec {
      inherit pkgs;
      inherit (pkgs) system;
      extraArgs = {
        inherit (self.inventory.${system}) inventory;
        secrets = homelab-private.secrets;
      };
      modules = [ ../cloud ];
      strip_nulls = false;
    };
  };
in
{
  aarch64-linux =
    let
      pkgs = import nixpkgs {
        system = "aarch64-linux";
        overlays = [ self.overlays.default ];
      };
    in
    pkgs.lib.recursiveUpdate (commonDerivations pkgs) {
      inherit (pkgs)
        linux_cn913x
        ubootCN9130_CF_Pro
        armTrustedFirmwareCN9130_CF_Pro
        ;

      installer_iso_lx2k = (nixpkgs.lib.nixosSystem {
        inherit (pkgs) system;
        specialArgs = { inherit inputs; };
        modules = installer_iso_modules ++ [{ imports = [ ../modules/hardware/lx2k.nix ]; }];
      }).config.system.build.isoImage;

      installer_iso_thinkpad_x13s = (nixpkgs.lib.nixosSystem {
        inherit (pkgs) system;
        specialArgs = { inherit inputs; };
        modules = installer_iso_modules ++ [
          ../modules/hardware/thinkpad_x13s.nix
          ({ config, ... }: {
            isoImage = {
              contents = [
                (
                  let
                    dtbPath = "dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
                  in
                  {
                    source = config.boot.loader.grub.extraFiles.${dtbPath};
                    target = "/boot/${dtbPath}";
                  }
                )
              ];
            };
          })
        ];
      }).config.system.build.isoImage;
      artichoke_image = self.nixosConfigurations.artichoke.config.system.build.sdImage;
      artichoke-test_image = self.nixosConfigurations.artichoke-test.config.system.build.sdImage;
      rhubarb_image = self.nixosConfigurations.rhubarb.config.system.build.sdImage;
    };

  x86_64-linux =
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [
          ipwatch.overlays.default
          runner-nix.overlays.default
          self.overlays.default
          webauthn-tiny.overlays.default
        ];
      };
    in
    pkgs.lib.recursiveUpdate (commonDerivations pkgs) {
      inherit (pkgs.pkgsCross.aarch64-multiplatform)
        ipwatch
        linux_cn913x
        runner-nix
        ubootCN9130_CF_Pro
        webauthn-tiny
        ;
    };
}
