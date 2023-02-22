{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];
  hardware.bluetooth.enable = true;

  fileSystems."/".options = [ "compress=zstd" "noatime" "discard=async" ];
  fileSystems."/nix".options = [ "compress=zstd" "noatime" "discard=async" ];
  fileSystems."/home".options = [ "compress=zstd" "noatime" "discard=async" ];
  zramSwap.enable = true;

  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "fido2-device=auto" ];
  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "carrot";

  services.fwupd.enable = true;

  users.mutableUsers = true;
  custom = {
    dev.enable = true;
    gui.enable = true;
    laptop.enable = true;
    users.jared.enable = true;
    remoteBuilders.aarch64builder.enable = true;
  };

  home-manager.users.jared = { config, pkgs, ... }: {
    services.kanshi = {
      profiles = {
        default = { outputs = [{ criteria = "eDP-1"; }]; };
        docked = {
          outputs = config.services.kanshi.profiles.default.outputs ++ [
            { criteria = "Lenovo Group Limited LEN P24q-20 V306P4GR"; mode = "2560x1440@74.78Hz"; }
          ];
        };
      };
    };

    home.packages = with pkgs; [
      (weechat.override { configure = { ... }: { scripts = with pkgs.weechatScripts; [ weechat-matrix ]; }; })
      (writeShellScriptBin "rdp" "${pkgs.freerdp}/bin/wlfreerdp /sec:tls /cert:tofu /v:laptop.work.home.arpa -grab-keyboard +auto-reconnect")
      (writeShellScriptBin "work-browser" "${chromium-wayland}/bin/chromium --user-data-dir=$HOME/.config/chromium-work --proxy-server=socks5://localhost:9050")
      age-plugin-yubikey
      freerdp
      outlook-webapp
      teams-webapp
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
