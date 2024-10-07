{
  config,
  extendModules,
  lib,
  modulesPath,
  pkgs,
  utils,
  ...
}:
let
  inherit (lib)
    attrNames
    filter
    getExe
    head
    mapAttrs'
    match
    mkForce
    mkIf
    mkMerge
    mkOption
    nameValuePair
    optionalString
    types
    ;

  inherit (utils.systemdUtils.network.units)
    linkToUnit
    netdevToUnit
    networkToUnit
    ;

  mkUnit = f: def: {
    inherit (def) enable;
    text = f def;
  };

  cfg = config.custom.image;

  installerCfg = cfg.installer;

  baseConfig = config;

  targetDeviceUnit = "${utils.escapeSystemdPath installerCfg.targetDisk}.device";

  noopService = {
    serviceConfig.ExecStart = [
      ""
      "/bin/true"
    ];
  };

  # Make the installer work with lots of common hardware.
  installerSystem = (
    extendModules {
      modules = [
        (
          { config, pkgs, ... }:
          let
            nixosInstaller = pkgs.writeShellApplication {
              name = "install-nixos";

              runtimeInputs = [
                pkgs.coreutils
                pkgs.curl
                pkgs.xz
              ];

              # TODO(jared): verification of image with existing systemd utilities
              # (importctl, etc.).
              text = ''
                curl --silent --location "''${1:-${cfg.update.source}/image.raw.xz}" | xz -d | dd bs=4M status=progress oflag=sync of=${installerCfg.targetDisk}
                echo "installation finished"
              '';
            };
          in
          {
            _file = "<homelab/nixos-modules/image/installer/default.nix>";

            imports = [ "${modulesPath}/profiles/all-hardware.nix" ];

            fileSystems = lib.mkForce { };
            boot.initrd.luks.devices = lib.mkForce { };

            networking.useNetworkd = true;

            boot.kernelParams = mkForce (
              let
                allowList = [ "^console=.*$" ];
              in
              filter (
                param: filter (allowRegex: match allowRegex param != null) allowList != [ ]
              ) baseConfig.boot.kernelParams
              ++ [
                "rd.systemd.gpt_auto=0" # disable gpt-auto-generator
              ]
            );

            boot.initrd.supportedFilesystems = [
              "btrfs"
              "ext4"
              "vfat"
            ];

            boot.initrd.systemd = {
              enable = true;

              contents."/etc/hosts".source = config.environment.etc.hosts.source;

              repart.enable = lib.mkForce false;

              emergencyAccess = true;

              initrdBin = [
                nixosInstaller
                pkgs.curl
                pkgs.iproute2
                pkgs.iputils
                pkgs.xz
              ];

              network = mkMerge [
                {
                  enable = true;
                  wait-online.anyInterface = true;
                }
                {
                  units = mapAttrs' (
                    n: v: nameValuePair "${n}.link" (mkUnit linkToUnit v)
                  ) config.systemd.network.links;
                }
                {
                  units =
                    mapAttrs' (n: v: nameValuePair "${n}.netdev" (mkUnit netdevToUnit v)) config.systemd.network.netdevs
                    // mapAttrs' (
                      n: v: nameValuePair "${n}.network" (mkUnit networkToUnit v)
                    ) config.systemd.network.networks;
                }
              ];

              services = {
                # We aren't a full-blown nixos system, don't do nixos activation or
                # switch-root.
                initrd-nixos-activation = noopService;
                initrd-switch-root = noopService;
                initrd-cleanup = noopService;

                install-nixos = {
                  requiredBy = [ "initrd.target" ];
                  description = "NixOS Installation";
                  unitConfig = {
                    OnFailure = [ "rescue.target" ];
                    OnSuccess = [ "reboot.target" ];
                  };
                  after = [
                    "initrd-fs.target"
                    "network.target"
                    targetDeviceUnit
                    "network-online.target"
                  ];
                  wants = [ "network-online.target" ];
                  requires = [ targetDeviceUnit ];
                  serviceConfig = {
                    Type = "oneshot";
                    StandardError = "journal+console";
                    StandardOutput = "journal+console";
                    ExecStart = getExe nixosInstaller;
                  };
                };
              };
            };

            system.build = {
              installerUki = pkgs.callPackage (
                { stdenv, systemdUkify }:

                stdenv.mkDerivation {
                  name = "installer-uki";
                  nativeBuildInputs = [ systemdUkify ];
                  buildCommand = ''
                    ukify build \
                      --no-sign-kernel \
                      --efi-arch=${pkgs.stdenv.hostPlatform.efiArch} \
                      --uname=${installerSystem.config.system.build.kernel.version} \
                      --stub=${installerSystem.config.systemd.package}/lib/systemd/boot/efi/linux${pkgs.stdenv.hostPlatform.efiArch}.efi.stub \
                      --linux=${installerSystem.config.system.build.kernel}/${installerSystem.config.system.boot.loader.kernelFile} \
                      --cmdline="${toString config.boot.kernelParams}" \
                      --initrd=${config.system.build.initialRamdisk}/${installerSystem.config.system.boot.loader.initrdFile} \
                      --os-release=@${installerSystem.config.environment.etc."os-release".source} \
                      ${optionalString installerSystem.config.hardware.deviceTree.enable "--devicetree=${installerSystem.config.hardware.deviceTree.package}/${installerSystem.config.hardware.deviceTree.name}"} \
                      --output=$out
                  '';
                }
              ) { };

              blsEntry = pkgs.writeText "entry.conf" (
                ''
                  title Installer
                  linux /linux
                  initrd /initrd
                ''
                + optionalString config.hardware.deviceTree.enable ''
                  devicetree /devicetree.dtb
                ''
                + ''
                  options ${toString config.boot.kernelParams}
                  architecture ${pkgs.stdenv.hostPlatform.efiArch}
                ''
              );
            };
          }
        )
      ];
    }
  );
in
{
  options.custom.image.installer = {
    targetDisk = mkOption {
      type = types.path;
      description = ''
        The path to the block device that the image will be installed on.
      '';
    };
  };

  config = mkIf cfg.enable {
    system.build = {
      inherit installerSystem;

      installerInitrd = installerSystem.config.system.build.initialRamdisk;

      networkInstaller = throw "unimplemented";

      diskInstaller = pkgs.callPackage ./image.nix {
        imageName = config.networking.hostName;

        bootFileCommands =
          let
            ukiCommands = ''
              echo ${installerSystem.config.system.build.installerUki}:/EFI/boot/boot${pkgs.stdenv.hostPlatform.efiArch}.efi >>$bootfiles
            '';
          in
          {
            "uefi" = ukiCommands;
            "bootLoaderSpec" =
              ''
                echo ${installerSystem.config.system.build.blsEntry}:/loader/entries/installer.conf >>$bootfiles
                echo ${installerSystem.config.system.build.kernel}/${installerSystem.config.system.boot.loader.kernelFile}:/linux >>$bootfiles
                echo ${installerSystem.config.system.build.initialRamdisk}/${installerSystem.config.system.boot.loader.initrdFile}:/initrd >>$bootfiles
              ''
              + optionalString config.hardware.deviceTree.enable ''
                echo ${installerSystem.config.hardware.deviceTree.package}/${installerSystem.config.hardware.deviceTree.name}:/devicetree.dtb >>$bootfiles
              '';
          }
          ."${head (attrNames cfg.boot)}";

        # TODO(jared): We assume the sector size of the installation media is
        # 512, I have yet to see a USB stick with a different sector size...
        sectorSize = 512;
      };
    };
  };
}
