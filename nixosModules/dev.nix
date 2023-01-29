{ config, lib, ... }:
let
  cfg = config.custom.dev;
in
with lib;
{
  options.custom.dev = {
    enable = mkEnableOption "dev setup";
    languages = {
      all = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable support for all languages
        '';
      };
    } // lib.listToAttrs (map (lang: lib.nameValuePair lang (mkEnableOption lang)) [
      "c"
      "go"
      "lua"
      "nix"
      "python"
      "rust"
      "typescript"
      "zig"
    ]);
  };

  config = mkIf cfg.enable {
    documentation = {
      enable = true;
      dev.enable = true;
      doc.enable = true;
      info.enable = true;
      man.enable = true;
    };

    programs = {
      adb.enable = true;
      flashrom.enable = true;
      mosh.enable = true;
      wireshark.enable = true;
    };

    environment.variables.EDITOR = lib.mkForce "nvim";

    nix.settings = {
      keep-outputs = true;
      keep-derivations = true;
    };

    programs.ssh.startAgent = true;

    networking.firewall.allowedTCPPorts =
      # wezterm-mux-server
      lib.optional (!config.custom.gui.enable) 8080;

    virtualisation.containers = {
      enable = !config.boot.isContainer;
      containersConf.settings.engine.detach_keys = "ctrl-q,ctrl-e";
    };
    virtualisation.podman = {
      enable = !config.boot.isContainer;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
