{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.custom.ddns;
in
{
  options.custom.ddns = {
    enable = mkEnableOption "ddns";

    interface = mkOption { type = types.str; };

    domain = mkOption { type = types.str; };

    ipv4.enable = mkEnableOption "watch for ipv4 address changes" // {
      default = true;
    };

    ipv6.enable = mkEnableOption "watch for ipv6 address changes" // {
      default = true;
    };

    subdomain = mkOption {
      type = types.str;
      default = config.networking.hostName;
      defaultText = ''config.networking.hostName'';
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.ipwatch_env = { };

    users.groups.cloudflare = { };
    systemd.tmpfiles.settings."10-update-cloudflare".${config.systemd.paths.update-cloudflare.pathConfig.PathChanged} = {
      f.group = config.users.groups.cloudflare.name;
      f.mode = "0660";
      z.group = config.users.groups.cloudflare.name;
      z.mode = "0660";
    };

    systemd.services.ipwatch.serviceConfig = {
      SupplementaryGroups = [ config.users.groups.cloudflare.name ];
      BindPaths = [
        config.systemd.paths.update-cloudflare.pathConfig.PathChanged
      ];
    };

    services.ipwatch = {
      enable = true;
      hooks.${cfg.interface} = {
        filters =
          [
            "IsGlobalUnicast"
            "!IsPrivate"
            "!IsLoopback"
            "!Is4In6"
          ]
          ++ lib.optionals (!cfg.ipv4.enable) [
            "!Is4"
          ]
          ++ lib.optionals (!cfg.ipv6.enable) [
            "!Is6"
          ];
        program = lib.getExe (
          pkgs.writeShellScriptBin "start-update-cloudflare" ''
            env | grep -e ^IS_IP6= -e ^IS_IP4= -e ^ADDR= >${config.systemd.paths.update-cloudflare.pathConfig.PathChanged}
          ''
        );
      };
    };

    systemd.paths.update-cloudflare = {
      pathConfig.PathChanged = "/run/update-cloudflare";
      wantedBy = [ "paths.target" ];
    };

    systemd.services.update-cloudflare = {
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      serviceConfig = {
        DynamicUser = true;
        EnvironmentFile = [
          config.sops.secrets.ipwatch_env.path
          config.systemd.paths.update-cloudflare.pathConfig.PathChanged
        ];
        Type = "oneshot";
        Restart = "on-failure";
        ExecStart = lib.getExe (
          (pkgs.writeShellApplication {
            name = "update-cloudflare";
            text =
              let
                updateCloudflare = name: recordType: ''
                  ${lib.getExe pkgs.curl} \
                    --silent \
                    --show-error \
                    --request PUT \
                    --header "Content-Type: application/json" \
                    --header "Authorization: Bearer ''${CF_API_TOKEN}" \
                    --data '{"type":"${recordType}","name":"${name}","content":"'"''${ADDR}"'","proxied":false}' \
                    "https://api.cloudflare.com/client/v4/zones/''${CF_ZONE_ID}/dns_records/''${CF_RECORD_ID_${recordType}}" | ${lib.getExe pkgs.jq}
                '';
              in
              ''
                if [[ 1 == "''${IS_IP6:-}" ]]; then
                  ${updateCloudflare "${cfg.subdomain}.${cfg.domain}" "AAAA"}
                elif [[ 1 == "''${IS_IP4:-}" ]]; then
                  ${updateCloudflare "${cfg.subdomain}.${cfg.domain}" "A"}
                else
                  echo "nothing to update"
                fi
              '';
          })
        );
      };
    };
  };
}
