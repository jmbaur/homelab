{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./qualcomm.nix ];

  options.hardware.chromebook.enable = lib.mkEnableOption "chromebook";

  config = lib.mkIf config.hardware.chromebook.enable {
    services.xserver.xkb.options = "ctrl:swap_lwin_lctl";
    services.xserver.xkb.model = "chromebook";

    # allow for CR50 TPM usage in initrd
    boot.initrd.availableKernelModules =
      [ "tpm_tis_spi" ]
      ++ (lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        "intel_lpss_pci"
        "spi_pxa2xx_platform"
        "spi_intel_pci"
      ]);

    services.udev.packages = [
      (pkgs.buildPackages.runCommand "chromiumos-autosuspend-udev-rules" { } ''
        mkdir -p $out/lib/udev/rules.d
        ${lib.getExe pkgs.buildPackages.python3} \
          ${config.systemd.package.src}/tools/chromiumos/gen_autosuspend_rules.py \
          >$out/lib/udev/rules.d/01-chromium-autosuspend.rules
      '')
    ];
  };
}
