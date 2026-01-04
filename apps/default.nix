inputs:

inputs.nixpkgs.lib.mapAttrs (
  system: pkgs:

  let
    inherit (pkgs) lib;

    inherit (lib)
      getExe
      getExe'
      ;

    mkApp = description: script: {
      type = "app";
      meta = { inherit description; };
      program = toString script;
    };
  in
  {
    setupPamU2f = mkApp "Setup U2F on a yubikey" (
      pkgs.writeShellScript "setup-pam-u2f" ''
        ${pkgs.pam_u2f}/bin/pamu2fcfg -opam://homelab
      ''
    );

    setupYubikey = mkApp "Setup common yubikey settings (enable openpgp & ssh resident key, remove default pins, etc.)" (
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

    flashKinesis = mkApp "Flash kinesis keyboard with custom QMK firmware (https://github.com/kinx-project/kint)" (
      pkgs.writeShellScript "flash-kinesis" ''
        ${pkgs.teensy-loader-cli}/bin/teensy-loader-cli -w -v --mcu=TEENSY40 ${pkgs.jmbaur-qmk-keyboards}/kinesis_kint41_jmbaur.hex
      ''
    );

    flashMoonlander = mkApp "Flash moonlander keyboard with custom QMK firmware" (
      pkgs.writeShellScript "flash-moonlander" ''
        ${pkgs.dfu-util}/bin/dfu-util -a 0 -d 0483:DF11 -s 0x8000000:leave -D ${pkgs.jmbaur-qmk-keyboards}/zsa_moonlander_jmbaur.bin
      ''
    );

    testDesktop = mkApp "Test changes to ./nixos-modules/desktop/* in a VM" (
      getExe
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
    );
  }
) inputs.self.legacyPackages
