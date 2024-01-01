inputs:
inputs.nixpkgs.lib.mapAttrs
  (directory: _:
  inputs.nixpkgs.lib.nixosSystem {
    modules = [
      { networking.hostName = directory; }
      inputs.self.nixosModules.default
      ./${directory}
    ];
  })
  (inputs.nixpkgs.lib.filterAttrs
    (_: entryType: entryType == "directory")
    (builtins.readDir ./.))

# TODO(jared): switch to image-based stuff
# installer_sd_image_cn9130_clearfog = mkInstaller {
#   modules = [
#     ({ lib, pkgs, modulesPath, ... }: {
#       disabledModules = [
#         # prevent initrd from requiring a bunch of kernel modules we don't
#         # need
#         "${modulesPath}/profiles/all-hardware.nix"
#       ];
#       imports = [ "${modulesPath}/installer/sd-card/sd-image-aarch64.nix" ];
#       sdImage.populateFirmwareCommands = lib.mkForce "";
#       sdImage.postBuildCommands = ''
#         dd if=${pkgs.cn9130CfProSdFirmware} of=$img bs=512 seek=4096 conv=notrunc,sync
#       '';
#       nixpkgs.hostPlatform = "aarch64-linux";
#       boot.initrd.systemd.enable = true;
#       hardware.clearfog-cn913x.enable = true;
#     })
#   ];
# };

# installer_sd_image_bpi_r3 = mkInstaller {
#   modules = [
#     ({
#       imports = [ ../nixos-modules/hardware/bpi-r3/sd-image.nix ];
#       nixpkgs.hostPlatform = "aarch64-linux";
#       hardware.bpi-r3.enable = true;
#       custom.server.enable = true; # limits packages needed for cross-compilation
#       custom.disableZfs = true;
#     })
#   ];
# };

# armada-388-clearfog-installer = mkInstaller {
#   modules = [
#     ({ config, lib, pkgs, modulesPath, ... }: {
#       disabledModules = [
#         # prevent initrd from requiring a bunch of kernel modules we don't
#         # have with the armada 388's kernel mvebu_v7_defconfig
#         "${modulesPath}/profiles/all-hardware.nix"
#       ];
#       imports = [
#         "${modulesPath}/profiles/installation-device.nix"
#         "${modulesPath}/installer/sd-card/sd-image.nix"
#       ];
#       hardware.armada-388-clearfog.enable = true;
#       networking.useNetworkd = true;
#       custom.server.enable = true;
#       custom.disableZfs = true;
#       environment.systemPackages = [
#         (pkgs.writeShellScriptBin "generate-macaddrs" ''
#           echo "ethaddr $(${lib.getExe pkgs.macgen})" | tee -a macaddrs
#           echo "eth1addr $(${lib.getExe pkgs.macgen})" | tee -a macaddrs
#           echo "eth2addr $(${lib.getExe pkgs.macgen})" | tee -a macaddrs
#           echo "eth3addr $(${lib.getExe pkgs.macgen})" | tee -a macaddrs
#           ${pkgs.ubootEnvTools}/bin/fw_setenv --script macaddrs
#           echo "wrote new macaddrs to uboot environment"
#         '')
#       ];
#       sdImage.populateFirmwareCommands = lib.mkForce "";
#       sdImage.populateRootCommands = ''
#         mkdir -p ./files/boot
#         ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
#       '';
#       sdImage.postBuildCommands = ''
#         dd if=${pkgs.ubootClearfog}/u-boot-with-spl.kwb of=$img bs=512 seek=1 conv=notrunc
#       '';
#     })
#   ];
# };
