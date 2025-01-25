{ config, lib, ... }:

let
  inherit (lib)
    concatLines
    concatMapStringsSep
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.yggdrasil;

  nodeSubmodule =
    { ... }:
    {
      options = {
        ip = mkOption { type = types.nonEmptyStr; };

        allowAll = mkEnableOption "allow all traffic from this node";

        allowedTCPPorts = mkOption {
          type = types.listOf types.ints.positive;
          default = [ ];
          description = ''
            Allowed TCP ports from this node
          '';
        };

        allowedUDPPorts = mkOption {
          type = types.listOf types.ints.positive;
          default = [ ];
          description = ''
            Allowed UDP ports from this node
          '';
        };
      };
    };
in
{
  options.custom.yggdrasil.nodes = mkOption {
    type = types.attrsOf (types.submodule nodeSubmodule);
    default = { };
  };

  config = mkIf config.services.yggdrasil.enable {
    networking.extraHosts = concatLines (
      mapAttrsToList (nodeName: nodeSettings: ''
        ${nodeSettings.ip} ${nodeName}.internal
      '') cfg.nodes
    );

    networking.firewall.extraInputRules = concatLines (
      mapAttrsToList (
        nodeName: nodeSettings:
        if nodeSettings.allowAll then
          ''
            ip6 saddr ${nodeSettings.ip} accept comment "accept all traffic from ${nodeName}"
          ''
        else
          lib.optionalString (nodeSettings.allowedTCPPorts != [ ]) ''
            ip6 saddr ${nodeSettings.ip} tcp dport { ${
              concatMapStringsSep ", " toString nodeSettings.allowedTCPPorts
            } } accept comment "accepted TCP ports from ${nodeName}"
          ''
          + lib.optionalString (nodeSettings.allowedUDPPorts != [ ]) ''
            ip6 saddr ${nodeSettings.ip} udp dport { ${
              concatMapStringsSep ", " toString nodeSettings.allowedUDPPorts
            } } accept comment "accepted UDP ports from ${nodeName}"
          ''
      ) cfg.nodes
    );
  };
}
