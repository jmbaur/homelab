{ config, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.binfmt.emulatedSystems = [ "wasm32-wasi" "aarch64-linux" ];

  nix = {
    gc.automatic = true;
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };
  environment.pathsToLink = [ "/share/nix-direnv" ];

  custom = {
    git.enable = true;
    neovim.enable = true;
    tmux.enable = true;
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

  environment.variables.HISTCONTROL = "ignoredups";
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = false;
    shellAliases = { grep = "grep --color=auto"; };
    promptInit = ''
      PS1="%F{cyan}%n@%m%f:%F{green}%c%f %% "
    '';
    # Prevent zsh-newuser-install from showing
    shellInit = ''
      zsh-newuser-install() { :; }
      bindkey -e
      bindkey \^U backward-kill-line
    '';
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
    '';
  };

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "dev";
  time.timeZone = "America/Los_Angeles";

  networking.useDHCP = false;
  networking.interfaces.ens18.useDHCP = true;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "helloworld"; # TODO(jared): remove me
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = lib.singleton (import ../../lib/ssh-keys.nix);
  };

  environment.systemPackages = with pkgs; [
    age
    awscli2
    bat
    bind
    buildah
    curl
    direnv
    dust
    exa
    fd
    ffmpeg-full
    fzf
    gh
    gh
    git-get
    gosee
    gotop
    grex
    gron
    htmlq
    htop
    jq
    keybase
    librespeed-cli
    mob
    mosh
    nix-direnv
    nix-prefetch-docker
    nix-tree
    nixopsUnstable
    nixos-generators
    nixpkgs-fmt
    nnn
    nushell
    openssl
    p
    patchelf
    pstree
    pwgen
    renameutils
    ripgrep
    rtorrent
    sd
    skopeo
    sl
    speedtest-cli
    stow
    tailscale
    tcpdump
    tea
    tealdeer
    tig
    tokei
    trash-cli
    tree
    unzip
    usbutils
    vim
    wget
    wget
    xdg-user-dirs
    xdg-utils
    xsv
    ydiff
    yq
    zip
    zoxide
  ];

  programs.mtr.enable = true;
  programs.mosh.enable = true;

  services.qemuGuest.enable = true;
  services.openssh.enable = true;
  services.tailscale.enable = true;
  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up -authkey $(cat /var/lib/tailscale/tskey)
    '';
  };

  networking.firewall.enable = false;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    containers = {
      enable = true;
      containersConf.settings = {
        containers.keyring = false; # TODO(jared): don't do this
        engine.detach_keys = "ctrl-q,ctrl-e";
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
