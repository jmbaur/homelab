{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.agentp;
in
{
  options.services.agentp.enable = lib.mkEnableOption "Portnox AgentP";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.agentp ];

    systemd.packages = [ pkgs.agentp ];
    systemd.services.agentpd = {
      wantedBy = [ "multi-user.target" ];
      path = [
        "/run/wrappers" # sudo
        pkgs.coreutils-full
        pkgs.dmidecode
        pkgs.findutils
        pkgs.gawk
        pkgs.iproute2
        pkgs.lshw
        pkgs.lsof
      ]
      ++ lib.optionals config.networking.networkmanager.enable [ pkgs.networkmanager ];
    };

    # agentpd writes 802.1X NetworkManager profiles that reference its certs
    # in /var/agentp/certs, which wpa_supplicant (the one actually reading
    # them) can't see from its RootDirectory. Create the directory up front
    # so the bind mount exists before agentpd first enrolls.
    systemd.tmpfiles.settings.agentp = {
      # Clients (run as any user) take a lock at /var/agentp/inst$UID.lock.
      "/var/agentp".d.mode = "1777";
      "/var/agentp/certs".d.mode = "0755";
    };
    systemd.services.wpa_supplicant.serviceConfig.BindReadOnlyPaths = [
      "-/var/agentp/certs"
    ];

    # agentpd also writes a wired 802.1X profile that matches every ethernet
    # device, which stops NetworkManager from creating its default DHCP
    # profile for them, so wired networking anywhere without 802.1X just
    # fails. Keep it around for manual use, but don't autoconnect it. This
    # edits the keyfile instead of using `nmcli connection modify` since
    # agentpd restarts NetworkManager after writing it, and NetworkManager
    # could otherwise write back its stale copy of the profile.
    systemd.paths.agentp-wired-profile = {
      wantedBy = [ "paths.target" ];
      pathConfig.PathChanged = "/etc/NetworkManager/system-connections/portnox-clear-wired";
    };
    systemd.services.agentp-wired-profile = {
      wantedBy = [ "multi-user.target" ];
      after = [ "NetworkManager.service" ];
      path = [
        pkgs.gnugrep
        pkgs.gnused
      ]
      ++ lib.optionals config.networking.networkmanager.enable [ pkgs.networkmanager ];
      serviceConfig.Type = "oneshot";
      script = ''
        profile=/etc/NetworkManager/system-connections/portnox-clear-wired
        if [[ ! -f $profile ]] || grep -q '^autoconnect=false$' "$profile"; then
          exit 0
        fi
        sed -i '/^\[connection\]$/a autoconnect=false' "$profile"
        nmcli connection load "$profile" || true
      '';
    };
  };
}
