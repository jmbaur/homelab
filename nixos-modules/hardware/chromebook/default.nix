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
  imports = [ ./trogdor.nix ];

  options.hardware.chromebook = {
    enable = lib.mkEnableOption "chromebook";
    laptop = lib.mkEnableOption "chromebook laptop (not chromebox)" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    services.evremap = {
      enable = true;
      settings.device_name =
        {
          x86_64 = "AT Translated Set 2 keyboard";
          aarch64 = "cros_ec";
        }
        .${pkgs.stdenv.hostPlatform.qemuArch};

      settings.remap = [
        {
          input = [
            "KEY_RIGHTALT"
            "KEY_BACKSPACE"
          ];
          output = [ "KEY_DELETE" ];
        }
        {
          input = [ "KEY_LEFTMETA" ];
          output = [ "KEY_LEFTCTRL" ];
        }
        {
          input = [ "KEY_LEFTCTRL" ];
          output = [ "KEY_LEFTMETA" ];
        }
        {
          input = [
            "KEY_LEFTALT"
            "KEY_UP"
          ];
          output = [ "KEY_PAGEUP" ];
        }
        {
          input = [
            "KEY_LEFTALT"
            "KEY_DOWN"
          ];
          output = [ "KEY_PAGEDOWN" ];
        }
        {
          input = [
            "KEY_LEFTALT"
            "KEY_LEFT"
          ];
          output = [ "KEY_HOME" ];
        }
        {
          input = [
            "KEY_LEFTALT"
            "KEY_RIGHT"
          ];
          output = [ "KEY_END" ];
        }
      ]
      ++
        # function keys
        lib.imap1
          (index: key: {
            input = [
              "KEY_RIGHTALT"
              key
            ];
            output = [ "KEY_F${toString index}" ];
          })
          [
            "KEY_BACK"
            "KEY_REFRESH"
            "KEY_FULL_SCREEN"
            "KEY_SCALE"
            "KEY_SYSRQ"
            "KEY_BRIGHTNESSDOWN"
            "KEY_BRIGHTNESSUP"
            "KEY_KBDILLUMTOGGLE"
            "KEY_PLAYPAUSE"
            "KEY_MUTE"
            "KEY_VOLUMEDOWN"
            "KEY_VOLUMEUP"
          ];
    };

    services.udev.packages = lib.optionals cfg.laptop [
      (pkgs.runCommand "chromiumos-autosuspend-udev-rules" { } ''
        mkdir -p $out/lib/udev/rules.d
        ${lib.getExe pkgs.buildPackages.python3} \
          ${config.systemd.package.src}/tools/chromiumos/gen_autosuspend_rules.py \
          >$out/lib/udev/rules.d/01-chromium-autosuspend.rules
      '')
    ];

    boot.kernelPatches = [
      {
        name = "google-firmware";
        patch = null;
        extraStructuredConfig.GOOGLE_FIRMWARE = lib.kernel.yes;
      }
    ];

    # allow for CR50 TPM usage in initrd
    boot.initrd.availableKernelModules = [
      "tpm_tis_spi"
    ]
    ++ (lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      "intel_lpss_pci"
      "spi_pxa2xx_platform"
      "spi_intel_pci"
    ]);
  };
}
