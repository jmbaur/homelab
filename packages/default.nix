inputs: with inputs;
let
  common_installer_modules = [
    self.nixosModules.default
    { custom.installer.enable = true; }
  ];

  installer_img_modules = common_installer_modules ++ [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
  ];

  installer_iso_modules = common_installer_modules ++ [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  commonDerivations = pkgs: {
    inherit (pkgs)
      flarectl
      grafana-dashboards
      jmbaur-github-ssh-keys
      jmbaur-keybase-pgp-keys
      ;

    installer_img = (nixpkgs.lib.nixosSystem {
      inherit (pkgs) system;
      modules = installer_img_modules;
    }).config.system.build.sdImage;

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
        ubootCN9130_CF_Pro
        armTrustedFirmwareCN9130_CF_Pro
        ;

      installer_iso_lx2k = (nixpkgs.lib.nixosSystem {
        inherit (pkgs) system;
        specialArgs = { inherit inputs; };
        modules = installer_iso_modules ++ [{ hardware.lx2k.enable = true; }];
      }).config.system.build.isoImage;

      installer_iso_thinkpad_x13s = (nixpkgs.lib.nixosSystem {
        inherit (pkgs) system;
        specialArgs = { inherit inputs; };
        modules = installer_iso_modules ++ [
          ({ config, ... }: {
            hardware.thinkpad-x13s.enable = true;
            isoImage = {
              makeEfiBootable = true;
              contents = [{
                source = "${config.boot.kernelPackages.kernel}/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
                target = "/boot/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
              }];
            };
          })
        ];
      }).config.system.build.isoImage;
      artichoke_sd_image = self.nixosConfigurations.artichoke.config.system.build.sdImage;
      rhubarb_sd_image = self.nixosConfigurations.rhubarb.config.system.build.sdImage;
    };

  x86_64-linux =
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ self.overlays.default ];
      };
    in
    commonDerivations pkgs;
}
