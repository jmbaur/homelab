{ config, pkgs, lib, ... }:
let
  cfg = config.hardware.lx2k;
in
{
  options.hardware.lx2k.enable = lib.mkEnableOption "hardware support for the Honeycomb LX2K board";
  config = lib.mkIf cfg.enable {
    boot.kernelParams = [ "arm-smmu.disable_bypass=0" "iommu.passthrough=1" ]; # for onboard nics
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    systemd.services = lib.listToAttrs (map
      (name: nameValuePair name {
        description = "SFP+ port enablement";
        script = "${pkgs.restool}/bin/ls-addni dpmac.%i";
        serviceConfig.Type = "oneshot";
        before = [ "network-pre.target" ];
        wants = [ "network-pre.target" ];
      })
      (map (i: "dpmac@${toString i}") [ 7 8 9 10 ]));

  };
}
