{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.chromebook;
in
{
  imports = [ ./qualcomm.nix ];

  options.hardware.chromebook = {
    enable = lib.mkEnableOption "chromebook";
    laptop = lib.mkEnableOption "chromebook laptop (not chromebox)" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.xkb = lib.mkIf cfg.laptop {
      options = "ctrl:swap_lwin_lctl";
      model = "chromebook";
    };

    services.udev.packages = lib.optionals cfg.laptop [
      (pkgs.buildPackages.runCommand "chromiumos-autosuspend-udev-rules" { } ''
        mkdir -p $out/lib/udev/rules.d
        ${lib.getExe pkgs.buildPackages.python3} \
          ${config.systemd.package.src}/tools/chromiumos/gen_autosuspend_rules.py \
          >$out/lib/udev/rules.d/01-chromium-autosuspend.rules
      '')
    ];

    # allow for CR50 TPM usage in initrd
    boot.initrd.availableKernelModules =
      [ "tpm_tis_spi" ]
      ++ (lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
        "intel_lpss_pci"
        "spi_pxa2xx_platform"
        "spi_intel_pci"
      ]);
  };
}
