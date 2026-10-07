inputs:

# OpenWrt One acting as a wired backhaul AP for celery. Every ethernet port is
# bridged together with both radios, so plugging either port into one of
# celery's LAN ports extends the LAN, and the other port is usable by wired
# clients. The SSIDs and passphrases match celery's, and 802.11r/k/v lets
# clients roam between the two APs.
#
# The passphrases are not in the nix store; they must be placed on the
# persistent state partition (one line, the passphrase only):
#   /var/lib/hostapd/wlan0.passphrase
#   /var/lib/hostapd/wlan1.passphrase

{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatLines
    getExe'
    mapAttrsToList
    range
    ;

  hostName = "leek";

  inherit (inputs.self.lib) wlan;

  channels = wlan.channels.${hostName};

  bridge = "br0";

  hostapdFormat = pkgs.formats.keyValue { };

  toHostapdConf = hostapdFormat.generate "hostapd.conf";

  bssSettings =
    name:
    wlan.roamingSettings
    // {
      interface = name;
      inherit bridge;
      inherit (wlan.networks.${name}) ssid;
      mobility_domain = wlan.networks.${name}.mobilityDomain;
      nas_identifier = "${hostName}-${name}";
      ap_isolate = 0;
      auth_algs = 1;
      ctrl_interface = "/run/hostapd";
      ctrl_interface_group = 0;
      ieee80211w = 1;
      ignore_broadcast_ssid = 0;
      logger_syslog = -1;
      logger_syslog_level = 2;
      macaddr_acl = 0;
      rsn_pairwise = "CCMP";
      sae_require_mfp = 1;
      utf8_ssid = 1;
      wmm_enabled = 1;
      wpa = 2;
      wpa_pairwise = "CCMP";
    };

  radios = {
    wlan0 = toHostapdConf (
      bssSettings "wlan0"
      // {
        inherit (channels.wlan0) channel;
        country_code = "US";
        driver = "nl80211";
        hw_mode = "g";
        ieee80211d = 1;
        ieee80211h = 1;
        ieee80211n = 1;
        ht_capab = "[RXLDPC][HT40-][GF][SHORT-GI-20][SHORT-GI-40][TX-STBC][RX-STBC1][MAX-AMSDU-7935]";
        noscan = 0;
        require_ht = 0;
        # Same as celery, older devices that only support wpa2-sha1 need
        # WPA-PSK.
        wpa_key_mgmt = "WPA-PSK WPA-PSK-SHA256 SAE FT-PSK";
      }
    );

    wlan1 = toHostapdConf (
      bssSettings "wlan1"
      // {
        inherit (channels.wlan1) channel;
        country_code = "US";
        driver = "nl80211";
        hw_mode = "a";
        ieee80211d = 1;
        ieee80211h = 1;
        ieee80211n = 1;
        ht_capab = "[LDPC][HT40+][GF][SHORT-GI-20][SHORT-GI-40][TX-STBC][RX-STBC1][MAX-AMSDU-7935]";
        require_ht = 0;
        ieee80211ac = 1;
        vht_capab = "[MAX-MPDU-11454][VHT160][RXLDPC][SHORT-GI-80][SHORT-GI-160][TX-STBC-2BY1][RX-STBC-1][SU-BEAMFORMER][SU-BEAMFORMEE][MU-BEAMFORMER][MU-BEAMFORMEE][MAX-A-MPDU-LEN-EXP7][RX-ANTENNA-PATTERN][TX-ANTENNA-PATTERN]";
        vht_oper_chwidth = 1;
        vht_oper_centr_freq_seg0_idx = channels.wlan1.centerChannel;
        ieee80211ax = 1;
        he_oper_chwidth = 1;
        he_oper_centr_freq_seg0_idx = channels.wlan1.centerChannel;
        he_su_beamformer = 1;
        he_su_beamformee = 1;
        noscan = 0;
        wpa_key_mgmt = "WPA-PSK-SHA256 SAE FT-PSK";
      }
    );
  };

in
{
  imports = [ inputs.openwrt-one.mixosModules.default ];

  nixpkgs.pkgs = import inputs.nixpkgs {
    localSystem = "x86_64-linux";
    crossSystem = "aarch64-linux";
    overlays = [
      inputs.self.overlays.default
      inputs.openwrt-one.overlays.default
    ];
  };

  hardware.openwrt-one.enable = true;

  # Everything needed to update the OS (fitImage), the bootloader (firmware),
  # or flash the board from scratch (bootstrapImages).
  custom.hydraJobs = [
    "toplevel"
    "fitImage"
    "firmware"
    "bootstrapImages"
  ];

  packages = [
    pkgs.hostapd
    pkgs.iw
    pkgs.kexec-tools
    pkgs.mtdutilsMinimal
    pkgs.openssh
  ];

  init.shell = {
    tty = "ttyS0";
    action = "askfirst";
    process = "/bin/sh";
  };

  users.root = {
    uid = 0;
    gid = 0;
    home = "/root";
    shell = "/bin/sh";
  };

  groups.root = {
    id = 0;
  };

  # Privilege separation user for sshd.
  users.sshd = {
    uid = 74;
    gid = 74;
  };

  groups.sshd = {
    id = 74;
  };

  etc."ssh/authorized_keys/root" = {
    source = pkgs.writeText "root-authorized-keys" (concatLines inputs.self.lib.sshKeys);
    mode = "0444";
  };

  etc."ssh/sshd_config".source = pkgs.writeText "sshd_config" ''
    AuthorizedKeysFile /etc/ssh/authorized_keys/%u
    HostKey /var/lib/sshd/ssh_host_ed25519_key
    KbdInteractiveAuthentication no
    PasswordAuthentication no
    PermitRootLogin prohibit-password
    Subsystem sftp internal-sftp
    UsePAM no
  '';

  services.sshd.run = pkgs.writeScript "sshd-run" ''
    #!/bin/sh

    set -e

    # The privilege separation directory, must be owned by root and not
    # writable by anyone else.
    mkdir -p /var/empty
    chmod 0555 /var/empty

    # Host keys live on the state partition so they persist across boots.
    mkdir -p /var/lib/sshd
    if ! [ -f /var/lib/sshd/ssh_host_ed25519_key ]; then
      ${getExe' pkgs.openssh "ssh-keygen"} -q -t ed25519 -N "" -f /var/lib/sshd/ssh_host_ed25519_key
    fi

    exec ${getExe' pkgs.openssh "sshd"} -D -e -f /etc/ssh/sshd_config
  '';

  # udhcpc's default script writes /etc/resolv.conf, which must be writable.
  etc."resolv.conf".source = "/run/resolv.conf";
  # Same as NixOS's default networking.timeServers
  etc."ntp.conf".source = pkgs.writeText "ntp.conf" (
    concatLines (map (n: "server ${toString n}.nixos.pool.ntp.org") (range 0 3))
  );

  # Bridges all ethernet ports together and gets an address for management
  # from celery's LAN. IPv6 is configured through SLAAC by the kernel.
  services.network.run = pkgs.writeScript "network-run" ''
    #!/bin/sh

    hostname ${hostName}

    # Wait (a bit) for both ethernet ports to show up.
    tries=0
    while [ "$(ls -d /sys/class/net/eth* 2>/dev/null | wc -l)" -lt 2 ] && [ "$tries" -lt 20 ]; do
      tries=$((tries + 1))
      sleep 0.5
    done

    ip link show ${bridge} >/dev/null 2>&1 || ip link add ${bridge} type bridge

    mkdir -p /var/lib/network

    for port in /sys/class/net/eth*; do
      port=$(basename "$port")

      # Only the WAN port has a MAC address in the factory partition, the
      # other is random on each boot. Generate a locally administered address
      # for such ports once and keep it on the state partition.
      if [ "$(cat /sys/class/net/"$port"/addr_assign_type)" = 0 ]; then
        # Give the bridge the factory MAC so that it has a stable DHCP lease
        # and SLAAC address.
        ip link set ${bridge} address "$(cat /sys/class/net/"$port"/address)"
      else
        mac_file=/var/lib/network/$port.mac
        if ! [ -f "$mac_file" ]; then
          ${getExe' pkgs.homelab-utils.macgen "macgen"} >"$mac_file"
        fi
        ip link set "$port" down
        ip link set "$port" address "$(cat "$mac_file")"
      fi

      ip link set "$port" master ${bridge}
      ip link set "$port" up
    done

    ip link set ${bridge} up

    exec udhcpc -f -i ${bridge} -x hostname:${hostName}
  '';

  services.hostapd.run = pkgs.writeScript "hostapd-run" ''
    #!/bin/sh

    set -e

    while ! [ -e /sys/class/net/${bridge} ]; do
      sleep 1
    done

    mkdir -p /run/hostapd

    for radio in wlan0 wlan1; do
      passphrase_file=/var/lib/hostapd/$radio.passphrase
      if ! [ -f "$passphrase_file" ]; then
        echo "missing $passphrase_file" >&2
        sleep 10
        exit 1
      fi
    done

    ${concatLines (
      mapAttrsToList (radio: conf: ''
        install -m0600 ${conf} /run/hostapd/${radio}.conf
        passphrase=$(cat /var/lib/hostapd/${radio}.passphrase)
        echo "wpa_passphrase=$passphrase" >>/run/hostapd/${radio}.conf
        echo "sae_password=$passphrase" >>/run/hostapd/${radio}.conf
      '') radios
    )}

    exec ${getExe' pkgs.hostapd "hostapd"} /run/hostapd/wlan0.conf /run/hostapd/wlan1.conf
  '';
}
