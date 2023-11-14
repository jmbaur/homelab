{ config, pkgs, inputs, ... }: {
  imports = [
    (import ../disko-single-disk-encrypted.nix "/dev/nvme0n1")
    ./hardware.nix
  ];

  custom.users.jared.enable =true;
  custom.dev.enable = true;
  custom.gui.enable = true;

  zramSwap.enable = true;
  hardware.bluetooth.enable = true;

  system.build.installer = (pkgs.nixos ({
    imports = [ inputs.self.nixosModules.default ./hardware.nix ];
    custom.tinyboot-installer.enable = true;
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "do-install" ''
        set -euo pipefail

        TMPDIR=$(mktemp -d); export TMPDIR
        trap 'rm -rf "$TMPDIR"' EXIT

        # populate nix db, so nixos-install doesn't complain
        export NIX_STATE_DIR=$TMPDIR/state
        nix-store --load-db < ${pkgs.closureInfo {
          rootPaths = [ config.system.build.toplevel ];
        }}/registration

        mkdir -p /mnt
        ${config.system.build.diskoScript}

        ${config.system.build.nixos-install}/bin/nixos-install --system ${config.system.build.toplevel} --keep-going --no-channel-copy -v --no-root-password --option binary-caches ""
      '')
    ];
  })).config.system.build.diskImage;
}
