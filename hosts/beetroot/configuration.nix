{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  hardware.bluetooth.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = false;
  networking.hostName = "beetroot";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  custom.neovim.enable = true;
  custom.tmux.enable = true;
  custom.git.enable = true;

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

  environment.variables = {
    XCURSOR_PATH = lib.mkForce [ "${pkgs.gnome.adwaita-icon-theme}/share/icons" ];
    NNN_TRASH = "1";
  };

  nixpkgs.overlays = [
    (self: super: {
      nix-direnv = super.nix-direnv.override { enableFlakes = true; };
    })
  ];

  environment.systemPackages = with pkgs; [
    # fdroidcl
    # fido2luks
    # start-recording
    # stop-recording
    age
    awscli2
    bat
    bitwarden
    buildah
    chromium
    direnv
    dust
    element-desktop-wayland
    exa
    fd
    ffmpeg-full
    firefox-wayland
    fzf
    geteltorito
    gh
    git
    git-get
    gosee
    gotop
    grex
    gron
    htmlq
    imv
    jq
    keybase
    librespeed-cli
    mob
    mosh
    mpv
    nix-direnv
    nix-prefetch-docker
    nix-tree
    nixos-generators
    nnn
    nushell
    nvme-cli
    openssl
    p
    pass
    pass-git-helper
    patchelf
    picocom
    plan9port
    pstree
    pwgen
    renameutils
    ripgrep
    rtorrent
    scrot
    sd
    signal-desktop
    skopeo
    sl
    speedtest-cli
    stow
    tailscale
    tcpdump
    tea
    tealdeer
    thunderbird-wayland
    tig
    tokei
    trash-cli
    unzip
    usbutils
    ventoy-bin
    vim
    wine64
    xdg-user-dirs
    xdg-utils
    xsv
    ydiff
    yq
    yubikey-manager
    yubikey-personalization
    zip
    zoxide
    zsh
  ];

  programs.ssh.startAgent = true;
  programs.mtr.enable = true;
  programs.wireshark.enable = true;
  programs.adb.enable = true;

  environment.etc = {
    "xdg/gtk-2.0/gtkrc".source = pkgs.writeText "gtkrc" ''
      gtk-theme-name = "Adwaita-dark"
    '';
    "xdg/gtk-3.0/settings.ini".source = pkgs.writeText "settings.ini" ''
      [Settings]
      gtk-theme-name = Adwaita-dark
      gtk-application-prefer-dark-theme = true
      gtk-key-theme-name = Emacs
    '';
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      export GTK_THEME=Adwaita-dark
      export XCURSOR_THEME=Adwaita
      # SDL:
      export SDL_VIDEODRIVER=wayland
      # QT (needs qt5.qtwayland in systemPackages):
      export QT_QPA_PLATFORM=wayland-egl
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      # Fix for some Java AWT applications (e.g. Android Studio),
      # use this if they aren't displayed properly:
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';
    extraPackages = with pkgs; [
      alacritty
      bemenu
      brightnessctl
      clipman
      fnott
      foot
      fuzzel
      gobar
      grim
      kanshi
      kitty
      mako
      pulseaudio
      slurp
      swayidle
      swaylock
      wev
      wl-clipboard
      wofi
      wtype
      zathura
    ];
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.greetd}/bin/agreety --cmd sway";
      };
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  xdg.mime.defaultApplications = {
    "application/pdf" = "firefox.desktop";
    "image/png" = "imv.desktop";
  };

  programs.wshowkeys.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
    media-session.config.bluez-monitor.rules = [
      {
        # Matches all cards
        matches = [{ "device.name" = "~bluez_card.*"; }];
        actions = {
          "update-props" = {
            "bluez5.reconnect-profiles" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
            # mSBC is not expected to work on all headset + adapter combinations.
            "bluez5.msbc-support" = true;
            # SBC-XQ is not expected to work on all headset + adapter combinations.
            "bluez5.sbc-xq-support" = true;
          };
        };
      }
      {
        matches = [
          # Matches all sources
          { "node.name" = "~bluez_input.*"; }
          # Matches all outputs
          { "node.name" = "~bluez_output.*"; }
        ];
        actions = {
          "node.pause-on-idle" = false;
        };
      }
    ];
  };

  programs.bash = {
    vteIntegration = true;
    shellAliases = { grep = "grep --color=auto"; };
    enableLsColors = true;
    enableCompletion = true;
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook bash)"
    '';
  };
  system.userActivationScripts.nix-direnv.text =
    let
      direnvrc = pkgs.writeText "direnvrc" ''
        source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc
      '';
    in
    ''
      ln -sf ${direnvrc} ''${HOME}/.direnvrc
    '';

  services.pcscd.enable = false;
  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.printing.enable = true;

  networking.firewall.enable = false;
  networking.nftables = {
    enable = true;
    rulesetFile = ./desktop.nft;
  };

  virtualisation = {
    containers = {
      enable = true;
      containersConf.settings.engine.detach_keys = "ctrl-q,ctrl-e";
    };
    podman.enable = true;
    libvirtd.enable = true;
  };


  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = true
    keep-derivations = true
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
