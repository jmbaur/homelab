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

  config = lib.mkIf cfg.enable {
    documentation.enable = true;
    documentation.doc.enable = true;
    documentation.info.enable = true;
    documentation.man.enable = true;
    documentation.nixos.enable = true;

    services.scx = {
      enable = lib.mkDefault true;
      scheduler = "scx_bpfland";
    };

    programs.ssh.startAgent = lib.mkDefault true;
    programs.gnupg.agent.enable = lib.mkDefault true;
    services.pcscd.enable = config.custom.desktop.enable;

    programs.adb.enable = lib.mkDefault true;

    boot.binfmt = {
      # Make sure builder isn't masquerading as being
      # able to do native builds for non-native
      # architectures.
      addEmulatedSystemsToNixSandbox = false;

      # Makes chroot/sandbox environments of
      # different architectures work.
      preferStaticEmulators = true;

      emulatedSystems =
        # TODO(jared): will not be fixed until we have https://github.com/nixos/nixpkgs/commits/a1d539f8eecffd258f3ed1ccc3a055aed56fbaa1
        lib.mkIf false (
          lib.optionals pkgs.stdenv.hostPlatform.isAarch64 [
            # TODO(jared): pkgsStatic.qemu-user doesn't build right now
            # "riscv32-linux"
            # "riscv64-linux"
            # "i686-linux"
            # "x86_64-linux"
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
            # "riscv32-linux"
            # "riscv64-linux"
            # "armv7l-linux"
            # "aarch64-linux"
          ]
        );
    };
  };
}
