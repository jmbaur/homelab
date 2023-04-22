{ config, lib, pkgs, ... }: {
  imports = [ ./mediatek.nix ];

  options.hardware.chromebook.enable = lib.mkEnableOption "chromebook";
  config = lib.mkIf config.hardware.chromebook.enable {
    services.xserver.xkbOptions = "ctrl:swap_lwin_lctl";
    services.xserver.xkbModel = "chromebook";
    programs.flashrom = {
      enable = true;
      package = pkgs.flashrom-cros;
    };

    boot.kernelPatches = [{
      name = "enable_spi_cr50_tpm";
      patch = null;
      extraStructuredConfig = {
        TCG_TIS_SPI_CR50 = lib.kernel.yes;
      };
    }];

    specialisation.flashfriendly.configuration.boot.kernelParams = [ "iomem=relaxed" ];
  };
}
