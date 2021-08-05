{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nixpkgs.overlays = [
    (
      import (
        builtins.fetchTarball {
          url =
            "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
        }
      )
    )
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  boot.kernel.sysctl = { "fs.inotify.max_user_watches" = "1048576"; };

  networking.hostName = "dev";

  networking.useDHCP = false;
  networking.interfaces.ens18.useDHCP = true;

  users.users.jared = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
  };

  environment.etc.gitconfig.source = ./gitconfig;

  environment.systemPackages = with pkgs; [
    git
    vim
    tmux
    curl
    wget
    htop
    atop
    fd
    jq
    killall
    ripgrep
    renameutils
    nixfmt
    mosh
    go
    gcc
    tree-sitter
    gopls
    nodePackages.typescript-language-server
    nodePackages.bash-language-server
    yaml-language-server
    pyright
    haskell-language-server
    rnix-lsp
    nodejs
    python3
    docker-compose
    skopeo
  ];

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    clock24 = true;
    baseIndex = 1;
    shortcut = "s";
    escapeTime = 10;
    secureSocket = true;
    aggressiveResize = true;
    terminal = "screen-256color";
    newSession = true;
    extraConfig = ''
      set -g set-clipboard on
      set -g renumber-windows on
      set -g update-environment "SSH_AUTH_SOCK"
      set -g default-shell /run/current-system/sw/bin/bash
      set-option -g focus-events on
      set-option -ga terminal-overrides ',xterm-256color:Tc'
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    package = pkgs.neovim-nightly;
    configure = {
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          easy-align
          vim-nix
          vim-lastplace
          vim-surround
          vim-commentary
          vim-rsi
          vim-fugitive
          vim-repeat
          typescript-vim
          vim-better-whitespace
          nvim-lspconfig
          lsp-colors-nvim
          gruvbox
          nvim-treesitter
          nvim-treesitter-textobjects
          telescope-nvim
          popup-nvim
          plenary-nvim
          nvim-autopairs
        ];
        opt = [];
      };
      customRC = ''
        lua << EOF
        ${builtins.readFile ./init.lua}
        EOF
      '';
    };
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true; # prunes weekly by default
  };

  services.qemuGuest.enable = true;

  services.openssh.enable = true;

  networking.firewall.enable = false;

  security.sudo.wheelNeedsPassword = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
