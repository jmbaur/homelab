{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.bluetooth.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelParams = [ "quiet" ];
  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "riscv64-linux"
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = false;
  networking.hostName = "beetroot";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "America/Los_Angeles";

  custom.common.enable = true;
  custom.desktop.enable = true;
  custom.home.enable = true;
  custom.virtualisation.enable = true;

  users.mutableUsers = lib.mkForce true;
  users.users.jared = {
    isNormalUser = true;
    initialPassword = "helloworld";
    extraGroups = [
      "adbusers"
      "dialout"
      "libvirtd"
      "networkmanager"
      "wheel"
      "wireshark"
    ];
  };
  services.snapper.configs.home = {
    subvolume = "/home";
    extraConfig = ''
      TIMELINE_CREATE=yes
      TIMELINE_CLEANUP=yes
    '';
  };

  nixpkgs.config.allowUnfree = true;

  programs.mtr.enable = true;
  programs.ssh.startAgent = true;
  programs.ssh.extraConfig = ''
    Host builder
      Hostname builder
      IdentityFile /etc/ssh/ssh_host_rsa_key
      User root
  '';
  programs.ssh.knownHosts.builder = {
    publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCdlL4oE5WXdJG0l9Cv31vuPkCHeh1m5ciLC+1iOR3PuFZBx5vlDig6v1Th4V2rL9UMP769+0NmHXXXH92IYz0/9Bt0Sv3vwfZlVA7Bhi2m1VWhaabMSXRpJ5r0FuG/FHTcIyg2yWRaf0S2CyJ0bTMD8CkzR/W05zaK32op6SUGAE8RqSWO3I4O5j4/wPEkY4Jjfry/sDnaOdMd1gd24p+xcdHWrJLQpzpkmJCViNSN5zMXvoccx5XuV1cFIp5HOKAC1QDoZ8n0iaj3H7GJ5f3iZcCNUNIJLFNkeYWLNGFz15xgxQ/Bngl7gJmwjchCm72s3lJMpWfX589PwkBg/hrpunT44oJ9dARdZY+V9ydFqu3jjP6xDYKVduVMeUZEBSvjmsWjmXnrciDO/4vWNBi9d+2NPXT3iLjIktx7SklYj40A/jOOHog1KLD36RYYqli9SidzUQhyvzytkh2Xe/TbGTG2Yhm7+0j7aelkvtDKq/dW5lmkZx6AcI04QOBJ2O+V98MLBWixkD9KQmBQsNr9gJKwAuu6IDi2ZtmVhHmcr+zQk8o7ixeOGc7x7BjSGTSgjrRsqGBzwNFBmtBWiLPJKwjKQd5obVFE16Sdb+8uVASeK117Kj6nnJIT6OrV89lJF4+tnsgkBSlvzs3tN06DqSTs7w4sxKku9wCQOjHI/w==";
    extraHostNames = [ "builder" ];
  };

  services.openssh.enable = true;
  services.openssh.listenAddresses = [
    { addr = "127.0.0.1"; port = 22; }
    { addr = "[::1]"; port = 22; }
  ];
  services.fwupd.enable = true;
  services.pcscd.enable = false;

  nix.settings.substituters = [ "https://cache.jmbaur.com/" ];
  nix.settings.trusted-public-keys = [ "cache.jmbaur.com:Zw4UQwDtZLWHgNrgKiwIyMDWsBVLvtDMg3zcebvgG8c=" ];
  nix.settings.trusted-users = [ "@wheel" ];
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  nix.buildMachines = [
    {
      hostName = "builder";
      systems = [ "x86_64-linux" "aarch64-linux" "riscv64-linux" ];
      maxJobs = 24; # number of cores
      speedFactor = 2; # arbitrary
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }
  ];
  nix.distributedBuilds = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
