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
    # presumably we'd be doing nix builds on a dev machine, so we need a mutable nix store
    custom.image.mutableNixStore = lib.mkDefault true;

    # home-manager is great for making user-specific changes, such as adding a bunch of dev-friendly tooling
    environment.systemPackages =
      lib.optionals (config.custom.image.enable -> config.custom.image.mutableNixStore)
        [
          pkgs.home-manager
        ];

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
