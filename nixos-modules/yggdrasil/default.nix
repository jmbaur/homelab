{ config, lib, ... }:

let
  inherit (lib)
    attrValues
    concatLines
    concatMapStringsSep
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.yggdrasil;

  allowedTCPPortsOption = mkOption {
    type = types.listOf types.ints.positive;
    default = [ ];
    description = ''
      Allowed TCP ports from this node
    '';
  };

  allowedUDPPortsOption = mkOption {
    type = types.listOf types.ints.positive;
    default = [ ];
    description = ''
      Allowed UDP ports from this node
    '';
  };

  nodeSubmodule =
    { ... }:
    {
      options = {
        ip = mkOption { type = types.nonEmptyStr; };

        allowAll = mkEnableOption "allow all traffic from this node";

        allowedTCPPorts = allowedTCPPortsOption;

        allowedUDPPorts = allowedUDPPortsOption;
      };
    };
in
{
  options.custom.yggdrasil = {
    all = {
      allowedTCPPorts = allowedTCPPortsOption;

      allowedUDPPorts = allowedUDPPortsOption;
    };

    nodes = mkOption {
      type = types.attrsOf (types.submodule nodeSubmodule);
      default = { };
    };
  };

  config = mkIf (config.services.yggdrasil.enable && cfg.nodes != { }) {
    networking.extraHosts = concatLines (
      mapAttrsToList (nodeName: nodeSettings: ''
        ${nodeSettings.ip} ${nodeName}.internal
      '') cfg.nodes
    );

    networking.firewall.extraInputRules = concatLines (
      (mapAttrsToList (
        nodeName: nodeSettings:
        if nodeSettings.allowAll then
          ''ip6 saddr ${nodeSettings.ip} accept comment "accept all traffic from ${nodeName}"''
        else
          lib.optionalString (nodeSettings.allowedTCPPorts != [ ])
            ''ip6 saddr ${nodeSettings.ip} tcp dport { ${
              concatMapStringsSep ", " toString nodeSettings.allowedTCPPorts
            } } accept comment "accepted TCP ports from ${nodeName}"''
          +
            lib.optionalString (nodeSettings.allowedUDPPorts != [ ])
              ''ip6 saddr ${nodeSettings.ip} udp dport { ${
                concatMapStringsSep ", " toString nodeSettings.allowedUDPPorts
              } } accept comment "accepted UDP ports from ${nodeName}"''
      ) cfg.nodes)
      ++ lib.optionals (cfg.all.allowedTCPPorts != [ ]) (
        let
          ips = concatMapStringsSep ", " (node: node.ip) attrValues cfg.nodes;
          ports = concatMapStringsSep ", " toString attrValues cfg.all.allowedTCPPorts;
        in
        ''ip6 saddr { ${ips} } tcp dport { ${ports} } accept''
      )
      ++ lib.optionals (cfg.all.allowedUDPPorts != [ ]) (
        let
          ips = concatMapStringsSep ", " (node: node.ip) attrValues cfg.nodes;
          ports = concatMapStringsSep ", " toString attrValues cfg.all.allowedUDPPorts;
        in
        ''ip6 saddr { ${ips} } udp dport { ${ports} } accept''
      )
    );
  };
}
