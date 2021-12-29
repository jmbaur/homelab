{ config, lib, pkgs, ... }: {
  imports = [ ../../../lib/nix-unstable.nix ../../../config ];

  nixpkgs.config.allowUnfree = true;

  custom = {
    git.enable = true;
    neovim.enable = true;
    tmux.enable = true;
  };

  networking.hostName = "dev";
  networking.interfaces.mv-eno2.useDHCP = true;

  programs.mosh.enable = true;
  programs.bash = {
    vteIntegration = true;
    undistractMe.enable = true;
    shellAliases = { grep = "grep --color=auto"; };
    enableLsColors = true;
    enableCompletion = true;
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook bash)"
    '';
  };

  environment.systemPackages = with pkgs; [
    age
    awscli2
    bat
    bind
    buildah
    buildah
    direnv
    dust
    exa
    fd
    ffmpeg-full
    fzf
    gh
    gh
    git
    git
    gotop
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
    nnn
    nushell
    openssl
    pass
    pass-git-helper
    patchelf
    picocom
    pstree
    pwgen
    renameutils
    ripgrep
    rtorrent
    sd
    skopeo
    skopeo
    sl
    speedtest-cli
    stow
    tailscale
    tcpdump
    tea
    tealdeer
    tig
    tig
    tmux
    tokei
    trash-cli
    unzip
    usbutils
    vim
    wget
    xdg-user-dirs
    xdg-utils
    xsv
    ydiff
    yq
    yubikey-manager
    yubikey-personalization
    zip
    zoxide
  ];

  services.openssh = { enable = true; ports = [ 2222 ]; };

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

  users = {
    mutableUsers = false;
    users.jared = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # TODO(jared): delete me
      openssh.authorizedKeys.keys = builtins.filter
        (str: builtins.stringLength str != 0)
        (lib.splitString "\n" (builtins.readFile ../../../lib/ssh_keys.txt));
    };
  };
}
