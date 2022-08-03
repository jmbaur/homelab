inputs: with inputs;
let
  withPkgs = system: f:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    f pkgs system;

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

  installer_img = system: (nixpkgs.lib.nixosSystem {
    inherit system;
    modules = installer_img_modules;
  }).config.system.build.sdImage;


  installer_iso = system: (nixpkgs.lib.nixosSystem {
    inherit system;
    modules = installer_iso_modules;
  }).config.system.build.isoImage;

  installer_iso_lx2k = system: (nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = installer_iso_modules ++ [{ hardware.lx2k.enable = true; }];
  }).config.system.build.isoImage;

  installer_iso_thinkpad_x13s = system: (nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = installer_iso_modules ++ [{ hardware.thinkpad-x13s.enable = true; }];
  }).config.system.build.isoImage;

  crs_305 = pkgs: system: pkgs.callPackage ./routeros/crs305/configuration.nix {
    inventoryFile = self.packages.${system}.inventory;
  };
  crs_326 = pkgs: system: pkgs.callPackage ./routeros/crs326/configuration.nix {
    inventoryFile = self.packages.${system}.inventory;
  };
  cap_ac = pkgs: system: pkgs.callPackage ./routeros/capac/secretsWrapper.nix {
    inventoryFile = self.packages.${system}.inventory;
    configurationFile = ./routeros/capac/configuration.nix;
  };

  cloud = pkgs: system: terranix.lib.terranixConfiguration {
    inherit pkgs system;
    extraArgs = {
      inherit (self.inventory.${system}) inventory;
      secrets = homelab-private.secrets;
    };
    modules = [ ./cloud ];
  };
  inventory = pkgs: system: pkgs.writeText
    "inventory.json"
    (builtins.toJSON (self.inventory.${system}.inventory));
in
{
  aarch64-linux =
    let
      system = "aarch64-linux";
    in
    {
      installer_iso = installer_iso system;
      installer_img = installer_img system;
      installer_iso_lx2k = installer_iso_lx2k system;
      installer_iso_thinkpad_x13s = installer_iso_thinkpad_x13s system;
      artichoke_sd_image = self.nixosConfigurations.artichoke.config.system.build.sdImage;
      rhubarb_sd_image = self.nixosConfigurations.rhubarb.config.system.build.sdImage;

      cap_ac = withPkgs system cap_ac;
      crs_305 = withPkgs system crs_305;
      crs_326 = withPkgs system crs_326;

      cloud = withPkgs system cloud;
      inventory = withPkgs system inventory;
    };

  x86_64-linux =
    let
      system = "x86_64-linux";
    in
    {
      installer_iso = installer_iso system;

      cap_ac = withPkgs system cap_ac;
      crs_305 = withPkgs system crs_305;
      crs_326 = withPkgs system crs_326;

      cloud = withPkgs system cloud;
      inventory = withPkgs system inventory;
    };
}
