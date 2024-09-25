{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.nestedBuilder;

  nestedBuilder = pkgs.pkgsCross.aarch64-multiplatform.nixos (
    { pkgs, modulesPath, ... }:
    {
      imports = [ "${modulesPath}/profiles/minimal.nix" ];
      config = lib.mkMerge [
        {
          services.qemuGuest = {
            enable = true;
            package =
              (pkgs.qemu_kvm.override {
                alsaSupport = false;
                pulseSupport = false;
                pipewireSupport = false;
                sdlSupport = false;
                jackSupport = false;
                gtkSupport = false;
                vncSupport = false;
                smartcardSupport = false;
                spiceSupport = false;
              }).ga;
          };

          boot.initrd.availableKernelModules = [
            "virtio_net"
            "virtio_pci"
            "virtio_mmio"
            "virtio_blk"
            "virtio_scsi"
            "9p"
            "9pnet_virtio"
          ];
          boot.initrd.kernelModules = [
            "virtio_balloon"
            "virtio_console"
            "virtio_rng"
            "virtio_gpu"
          ];
          boot.kernelParams = [ "console=ttyAMA0,115200" ];
        }
        {
          system.stateVersion = config.system.stateVersion;

          boot.loader.external = {
            enable = true;
            installHook = lib.getExe' pkgs.coreutils "true";
          };

          fileSystems."/" = {
            fsType = "tmpfs";
            options = [ "mode=0755" ];
          };
          fileSystems."/nix/store" = {
            fsType = "9p";
            device = "nix-store";
            options = [
              "trans=virtio"
              "version=9p2000.L"
              "msize=16384"
              "cache=loose"
            ];
          };

          system.switch.enable = false;

          boot.initrd.systemd.enable = true;

          users.users.root.password = "";
        }
      ];
    }
  );

  startScript = pkgs.writeShellApplication {
    name = "qemu-builder";
    runtimeInputs = [ pkgs.qemu ];
    text =
      # bash
      ''
        qemu-system-aarch64 -machine virt -cpu cortex-a53 -m ${toString cfg.memory}G -smp ${toString cfg.cpus} -nographic \
          -virtfs local,path=/nix/store,security_model=none,multidevs=remap,mount_tag=nix-store \
          -kernel ${nestedBuilder.config.system.build.kernel}/${nestedBuilder.config.system.boot.loader.kernelFile} \
          -initrd ${nestedBuilder.config.system.build.initialRamdisk}/${nestedBuilder.config.system.boot.loader.initrdFile} \
          -append "init=${nestedBuilder.config.system.build.toplevel}/init ${toString nestedBuilder.config.boot.kernelParams}"
      '';
  };
in
{
  options.custom.nestedBuilder = {
    enable = lib.mkEnableOption "nested builder";

    memory = lib.mkOption {
      type = lib.types.int;
      default = 1;
    };

    cpus = lib.mkOption {
      type = lib.types.int;
      default = 1;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !pkgs.stdenv.hostPlatform.isAarch64;
        message = "no need for nested builder, host platform is already aarch64";
      }
    ];

    system.build = {
      inherit nestedBuilder;
    };

    systemd.services.qemu-builder = {
      serviceConfig.ExecStart = lib.getExe startScript;
      wantedBy = [ "multi-user.target" ];
    };
  };
}
