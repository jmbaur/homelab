{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.nestedBuilder;

  outerConfig = config;

  nestedBuilder = pkgs.pkgsCross.aarch64-multiplatform.nixos (
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [ "${modulesPath}/profiles/minimal.nix" ];
      config = lib.mkMerge [
        {
          system.stateVersion = outerConfig.system.stateVersion;

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
          boot.loader.external = {
            enable = true;
            installHook = lib.getExe' pkgs.coreutils "true";
          };

          fileSystems."/" = {
            fsType = "tmpfs";
            options = [ "mode=0755" ];
          };
          fileSystems."/overlay/lower/nix" = {
            neededForBoot = true;
            fsType = "9p";
            device = "nix-store";
            options = [
              "cache=loose"
              "msize=16384"
              "ro"
              "trans=virtio"
              "version=9p2000.L"
            ];
          };
          fileSystems."/overlay/merged/nix/store" = {
            neededForBoot = true;
            overlay = {
              lowerdir = [ "/overlay/lower/nix/store" ];
              upperdir = "/overlay/upper";
              workdir = "/overlay/work";
            };
            # Ensure systemd knows the ordering dependency between this mmount and
            # the mount at /nix/store. This ensures they are unmounted in the correct
            # order as well.
            options = [ "x-systemd.before=nix-store.mount" ];
          };
          fileSystems."/nix/store" = {
            device = "/overlay/merged/nix/store";
            options = [
              # "ro"
              "bind"
            ];
          };

          boot.readOnlyNixStore = false;

          system.switch.enable = false;

          boot.initrd.systemd.enable = true;

          users.users.root.password = builtins.warn "TODO: don't set root password" "";

          nix.package = pkgs.nixVersions.nix_2_24_sysroot;
          nix.settings = {
            store = "local-overlay://?root=/overlay/merged&lower-store=/overlay/lower?read-only=true&upper-layer=/overlay/upper&check-mount=false";
            experimental-features = [
              "local-overlay-store"
              "read-only-local-store"
              "daemon-trust-override"
            ];
          };

          systemd.sockets.nix-daemon.socketConfig.ListenStream = [
            ""
            "vsock:3:1024"
          ];

          systemd.services.nix-daemon.serviceConfig.ExecStart = [
            ""
            "@${lib.getExe' config.nix.package "nix-daemon"} nix-daemon --daemon --force-trusted"
          ];
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
          -device vhost-vsock-pci,guest-cid=3 \
          -virtfs local,path=/nix,readonly=on,security_model=none,multidevs=remap,mount_tag=nix-store \
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
