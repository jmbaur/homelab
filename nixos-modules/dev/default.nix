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
    # home-manager is great for making user-specific changes, such as adding a bunch of dev-friendly tooling
    environment.systemPackages = [ pkgs.home-manager ];

    documentation.enable = true;
    documentation.doc.enable = true;
    documentation.info.enable = true;
    documentation.man.enable = true;
    documentation.nixos.enable = true;

    programs.ssh.startAgent = lib.mkDefault true;
    programs.gnupg.agent.enable = lib.mkDefault true;
    services.pcscd.enable = config.custom.desktop.enable;
  };
}
