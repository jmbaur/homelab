{ config, lib, pkgs, ... }:
let
  mgmt-iface = "enp5s0";
  mgmt-address = "192.168.88.3";
  mgmt-network = "192.168.88.0";
  mgmt-gateway = "192.168.88.1";
  mgmt-netmask = "255.255.255.0";
  mgmt-prefix = 24;
in
{
  imports = [ ./hardware-configuration.nix ];

  hardware.cpu.amd.updateMicrocode = true;

  custom.common.enable = true;
  custom.deploy.enable = true;

  systemd.services."serial-getty@ttyS2" = {
    enable = true;
    wantedBy = [ "getty.target" ]; # to start at boot
    serviceConfig.Restart = "always"; # restart when session is closed
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "riscv64-linux"
  ];
  boot.kernelParams = [
    "ip=${mgmt-address}::${mgmt-gateway}:${mgmt-netmask}:${config.networking.hostName}:${mgmt-iface}::::"
    "console=ttyS2,115200"
    "console=tty1"
  ];
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

  networking.interfaces.${mgmt-iface} = {
    useDHCP = false;
    ipv4.addresses = [{ address = mgmt-address; prefixLength = mgmt-prefix; }];
    ipv4.routes = [{ address = mgmt-network; prefixLength = mgmt-prefix; via = mgmt-gateway; }];
  };
  networking.interfaces.enp3s0.useDHCP = true;

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../../lib/ssh-keys.nix);
  };

  services.openssh.permitRootLogin = "yes";
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCkCEtRXKnC9trPlUjc2ogZOx87cCmRz7eQkJRlQahubHhwN/IhzKR9sybSr7+ejdb+nR9uN8FyBtrV4BRuKNLOoQs2r1WZZfXzYQJWQg0B1vSvwjsL30lRE+i1InzVUbS/iDHgckM9OAMNqaMrTY9C4uepHUnFLu6U7GaeyPk/caz0eCnnOh0JDAcHytIRPC35/9+VO80DIJIwLycdtbVhRoQQJfl0kfNLCR71TmE50+7/tfBlzLjDmZqtPnuFnhSGOdRlB8SoXFQQGooryoaSXXqVHOAM5hXgsjtHMo4+9Orf01Y+RERuvhEH6tK3bxG6visgaofp+JJRzx2cpTKOZnZOO541YlWGEneXpGXwh3eoVKNArG+hPg1KURl7p5KDL4VaGK19XqFJpYb+LrgCWQcFRzkHVikcK+zOjS9rB5RrcdLwd5YQUzFVyTim/3BgUdfaoKknoUod2smj4bPZYaStcmMNMzNjR2WqfIeSglu2Xmru14smxxr10NBi6xrLy3nnxG+j/2RQFmQwvd2UoAWcJHZOCuukvpxIanZDO0X+y0hAuKGZEwfV2bk6F+nWKKXGod1qnG538M2ybUen5dwvfmjkcEoLwQHWaRMzViGwrL3juGsvOzYl5N8Es0X67jL8eVkIJvxeTEVPqpa9p30LimOMCi+aWncwSiAQdQ== root@beetroot"
  ];

  services.iperf3.enable = true;

  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
