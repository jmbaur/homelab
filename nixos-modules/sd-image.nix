{ config, pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/sd-card/sd-image.nix" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.efiSysMountPoint = "/boot/firmware";
  boot.loader.efi.canTouchEfiVariables = false;

  sdImage.firmwareSize = 512;
  sdImage.populateRootCommands = '''';
  sdImage.populateFirmwareCommands =
    let
      entry = pkgs.writeText "nixos.conf" ''
        title nixos
        linux /linux
        initrd /initrd
        options init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}
      '';
    in
    ''
      mkdir -p firmware/{EFI/boot,loader/entries}
      cp -r ${config.hardware.deviceTree.package} firmware/dtb
      cp ${config.system.build.toplevel}/kernel firmware/kernel
      cp ${config.system.build.toplevel}/initrd firmware/initrd
      cp ${entry} firmware/loader/entries/nixos.conf
      cp ${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${pkgs.stdenv.hostPlatform.efiArch}.efi firmware/EFI/boot/boot${pkgs.stdenv.hostPlatform.efiArch}.efi
    '';
}
