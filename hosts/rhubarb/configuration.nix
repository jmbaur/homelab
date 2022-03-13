{ config, lib, pkgs, ... }:
{
  custom.common.enable = true;
  custom.deploy.enable = true;

  zramSwap = {
    enable = true;
    swapDevices = 1;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  networking = {
    hostName = "rhubarb";
    interfaces.eth0.useDHCP = true;
  };

  environment.systemPackages = with pkgs; [
    ansible
    deploy-rs.deploy-rs
    git
    terraform
  ];

  nix.buildMachines = [{
    hostName = "kale";
    systems = [ "x86_64-linux" "aarch64-linux" ];
    maxJobs = 1;
    speedFactor = 2;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [ ];
  }];
  nix.distributedBuilds = true;
  # Speeds things up by downloading dependencies remotely:
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';

  users.users.jared = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$HvZQftB0alLgxWLr$0NevK6oxPmOdjX.YuPjdgoCV0d5Ca8f/3uccn/WkNownDcT9fRbSwPuaID4AO0NubE0NfBrJR4eRKT/6Zgc4L0";
  };

  programs.ssh = {
    knownHosts = {
      localhost = {
        hostNames = [ "localhost" ];
        publicKey = lib.last (import ../../data/rhubarb-ssh-keys.nix);
      };
      broccoli = {
        hostNames = [ "broccoli" ];
        publicKey = "broccoli ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG5CvQypTDJ1jl+6/xBw7DLITOCzIwZRZIAefI3+uV6M";
      };
      kale = {
        hostNames = [ "kale" ];
        publicKey = "kale ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINSDTqHc9WfeZxTL97QzcmNAGUP/Qt2J5h3q1OqOvIen";
      };
    };
    extraConfig = ''
      Host kale rhubarb asparagus broccoli
        User root
        IdentitiesOnly yes
        IdentityFile /etc/ssh/ssh_host_ed25519_key
    '';
  };
}
