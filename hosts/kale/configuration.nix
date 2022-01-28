{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  hardware.cpu.amd.updateMicrocode = true;

  systemd.services."serial-getty@ttyS2" = {
    enable = true;
    wantedBy = [ "getty.target" ]; # to start at boot
    serviceConfig.Restart = "always"; # restart when session is closed
  };
  boot.kernelParams = [
    "ip=::::${config.networking.hostName}:enp5s0:dhcp:::"
    "console=ttyS2,115200"
    "console=tty1"
  ];
  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" "/etc/ssh/ssh_host_rsa_key" ];
      authorizedKeys = builtins.filter
        (key: key != "")
        (lib.splitString
          "\n"
          (builtins.readFile (import ../../lib/ssh-keys.nix))
        );
    };
  };

  networking.hostName = "kale";
  time.timeZone = "America/Los_Angeles";

  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;
  networking.interfaces.enp5s0.useDHCP = true;

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../../lib/ssh-keys.nix);
  };

  environment.systemPackages = with pkgs; [ tmux vim ];
  environment.variables.EDITOR = "vim";

  services.iperf3.enable = true;

  networking.firewall.enable = false;
  networking.nftables = {
    enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
