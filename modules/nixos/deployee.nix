{ config, lib, ... }:
let
  cfg = config.custom.deployee;
in
with lib;
{
  options.custom.deployee = {
    enable = mkEnableOption "deploy target";
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    authorizedKeyFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = (cfg.authorizedKeyFiles != [ ] || cfg.authorizedKeys != [ ]);
      message = "No authorized keys configured for deployee";
    }];

    services.openssh = {
      enable = true;
      listenAddresses = [ ]; # this defaults to all addresses
    };

    users.users.root.openssh.authorizedKeys = {
      keys = cfg.authorizedKeys;
      keyFiles = cfg.authorizedKeyFiles;
    };
  };
}

