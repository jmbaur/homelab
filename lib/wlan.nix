# Wireless networks shared by every AP in the house (celery, plus any wired
# backhaul APs such as leek). Keeping them in one place ensures the SSIDs and
# 802.11r mobility domains match, which clients require to roam between APs.
{
  networks = {
    wlan0 = {
      ssid = "Silence of the LANs";
      mobilityDomain = "a1c0";
    };
    wlan1 = {
      ssid = "SpiderLAN";
      mobilityDomain = "a1c1";
    };
  };

  # Pinned channels for each AP, on non-overlapping channels so APs don't
  # contend with each other for airtime. 5GHz channels are 80MHz wide and avoid
  # DFS channels, so APs come up without a CAC delay and never move channels
  # due to radar.
  channels = {
    celery = {
      wlan0.channel = 1;
      wlan1 = {
        channel = 36;
        centerChannel = 42;
      };
    };
    leek = {
      wlan0.channel = 11;
      wlan1 = {
        channel = 149;
        centerChannel = 155;
      };
    };
  };

  # hostapd settings enabling fast roaming (802.11r/k/v) between APs. Only
  # FT-PSK is offered: its FT keys are derived locally from the passphrase, so
  # the APs need no R0KH/R1KH key distribution among each other. WPA3 (SAE)
  # clients still roam, but with a full SAE authentication to the new AP.
  # nas_identifier must be set per-AP.
  #
  # TODO: FT-SAE would be nice to have, so WPA3 clients also get fast roaming.
  # Its PMK comes from the SAE exchange with the first AP, so it requires
  # R0KH/R1KH entries and a shared secret (ft_r0kh_r1kh_key) on every AP.
  roamingSettings = {
    ft_over_ds = 0;
    ft_psk_generate_local = 1;
    bss_transition = 1;
    rrm_neighbor_report = 1;
    rrm_beacon_report = 1;
  };
}
