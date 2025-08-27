{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.dev;
in
{
  options.custom.dev.enable = lib.mkEnableOption "dev setup";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        documentation.enable = true;
        documentation.doc.enable = true;
        documentation.info.enable = true;
        documentation.man.enable = true;
        documentation.nixos.enable = true;

        programs.ssh.startAgent = lib.mkDefault true;
        programs.gnupg.agent.enable = lib.mkDefault true;
        services.pcscd.enable = lib.mkDefault config.custom.desktop.enable;

        programs.adb.enable = lib.mkDefault true;

        services.udev.packages = [
          (pkgs.concatTextFile {
            name = "openocd-udev-rules";
            files = [ "${pkgs.openocd}/share/openocd/contrib/60-openocd.rules" ];
            destination = "/lib/udev/rules.d/60-openocd.rules";
          })
        ];

        boot.binfmt = {
          # Make sure builder isn't masquerading as being
          # able to do native builds for non-native
          # architectures.
          addEmulatedSystemsToNixSandbox = false;

          # Makes chroot/sandbox environments of
          # different architectures work.
          preferStaticEmulators = true;

          emulatedSystems =
            if (lib.warn "pkgsStatic.qemu-user doesn't build right now" true) then
              [ ]
            else
              (
                lib.optionals pkgs.stdenv.hostPlatform.isAarch64 [
                  "riscv32-linux"
                  "riscv64-linux"
                  "i686-linux"
                  "x86_64-linux"
                ]
                ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
                  "riscv32-linux"
                  "riscv64-linux"
                  "armv7l-linux"
                  "aarch64-linux"
                ]
              );
        };
      }
    ]
  );
}
