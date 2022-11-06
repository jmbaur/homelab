{ config, lib, pkgs, ... }: {
  options.custom.remoteBuilders = {
    aarch64builder.enable = lib.mkEnableOption "aarch64 builder";
  };
  config = {
    nix.buildMachines =
      (lib.optional config.custom.remoteBuilders.aarch64builder.enable {
        protocol = "ssh-ng";
        hostName = "aarch64builder";
        systems = [ "aarch64-linux" "armv7l-linux" ];
        maxJobs = 8;
        speedFactor = 2;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
      })
    ;
    nix.distributedBuilds = true;
    # optional, useful when the builder has a faster internet connection than yours
    nix.extraOptions = ''
      builders-use-substitutes = true
    '';

    programs.ssh = {
      knownHostsFiles = [
        (pkgs.writeText "known_hosts" ''
          kale.mgmt.home.arpa ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6q44hTsu6FVYG5izJxymw33SZJRDMttHxrwNBqdSJl
        '')
      ];
      extraConfig = ''
        Host aarch64builder
        User builder
        HostName kale.mgmt.home.arpa
        IdentitiesOnly yes
        IdentityFile /etc/ssh/ssh_host_ed25519_key
      '';
    };
  };
}
