{ config, lib, pkgs, ... }: {
  custom = {
    common.enable = true;
    deployee = {
      enable = true;
      authorizedKeyFiles = [
        (import ../../data/jmbaur-ssh-keys.nix)
        ../../data/deployer-ssh-keys.txt
      ];
    };
  };

  zramSwap.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_5_18;

  networking = {
    hostName = "rhubarb";
    useDHCP = false;
    useNetworkd = true;
  };
  services.resolved = {
    enable = true;
    # The RPI does not have an RTC, so DNSSEC without an accurate time does not
    # work, which means NTP servers cannot be queried.
    dnssec = "false";
  };

  services.greetd = {
    enable = true;
    settings = rec {
      default_session = {
        user = config.users.users.browser.name;
        command = "${pkgs.greetd.greetd}/bin/agreety --cmd '${pkgs.cage}/bin/cage -d -- ${pkgs.firefox-wayland}/bin/firefox https://kernel.org/'";
      };
      initial_session = default_session;
    };
  };

  systemd.network = {
    enable = true;
    networks.wired = {
      name = "eth*";
      DHCP = "yes";
      dhcpV4Config.ClientIdentifier = "mac";
    };
  };

  users.users = {
    browser.isNormalUser = true;
    jared = {
      isNormalUser = true;
      extraGroups = [ "dialout" "wheel" ];
      packages = with pkgs; [ picocom tmux wol ];
      openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
    };
  };

  system.stateVersion = "22.11";
}
