{ config, lib, pkgs, ... }: {
  boot.isContainer = true;
  custom.common.enable = true;
  networking = {
    hostName = "dev";
    interfaces.mv-trusted.useDHCP = true;
  };
  services.openssh.enable = true;
  users.users.jared = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
    extraGroups = [/*"wheel"*/];
  };
  nixpkgs.config.allowUnfree = true;

  system.userActivationScripts.nix-direnv.text = ''
    ln -sfT ${pkgs.nix-direnv}/share/nix-direnv/direnvrc ''${HOME}/.direnvrc
  '';
  nixpkgs.overlays = [
    (self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; } )
  ];
  environment.pathsToLink = [ "/share/nix-direnv" ];
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  environment.systemPackages = with pkgs; [
    age
    awscli2
    bat
    black
    cargo
    clang-tools
    direnv
    dust
    efm-langserver
    exa
    fd
    fzf
    geteltorito
    gh
    git
    git-get
    gmni
    go_1_18
    gopls
    gosee
    gotools
    gotop
    grex
    gron
    htmlq
    jq
    keybase
    librespeed-cli
    luaformatter
    mob
    mosh
    nix-direnv
    nix-prefetch-docker
    nix-prefetch-git
    nix-tree
    nixos-generators
    nixpkgs-fmt
    nnn
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodejs
    nvme-cli
    openssl
    p
    patchelf
    picocom
    pinentry
    pstree
    pwgen
    pyright
    python3
    ripgrep
    rtorrent
    rust-analyzer
    rustfmt
    sd
    shfmt
    sl
    smartmontools
    speedtest-cli
    sshfs
    ssm-session-manager-plugin
    stow
    sumneko-lua-language-server
    tailscale
    tcpdump
    tea
    tealdeer
    texlive.combined.scheme-medium
    tig
    tokei
    trash-cli
    tree-sitter
    unzip
    usbutils
    ventoy-bin
    vim
    xdg-user-dirs
    xdg-utils
    xsv
    ydiff
    yq
    yubikey-manager
    yubikey-personalization
    zf
    zig
    zip
    zls
    zoxide
  ];
  programs.bash = {
    interactiveShellInit = ''
      eval "$(${pkgs.direnv}/bin/direnv hook bash)"
    '';
    shellAliases.grep = "grep --color=auto";
  };
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    shortcut = "s";
    keyMode = "vi";
    clock24 = true;
    baseIndex = 1;
    escapeTime = 10;
  };
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      pull.rebase = true;
      user = {
        name = "Jared Baur";
        email = "jaredbaur@fastmail.com";
        signingKey = "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBD1B20XifI8PkPylgWlTaPUttRqeseqI0cwjaHH4jKItEhX8i5+4PcbtJAaJAOnFe28E8OMyxxm5Tl3POkdC8WsAAAAEc3NoOg==";
      };
      alias = {
          st = "status --short --branch";
          di = "diff";
          br = "branch";
          co = "checkout";
          lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      };
      gpg.format = "ssh";
    };
  };
  programs.neovim =
    let
      settings = pkgs.vimUtils.buildVimPlugin { name = "settings"; src = builtins.path { path = ../../modules/neovim/settings; }; };
      telescope-zf-native = pkgs.vimUtils.buildVimPlugin {
        name = "telescope-zf-native.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "natecraddock";
          repo = "telescope-zf-native.nvim";
          rev = "76ae732e4af79298cf3582ec98234ada9e466b58";
          sha256 = "sha256-acV3sXcVohjpOd9M2mf7EJ7jqGI+zj0BH9l0DJa14ak=";
        };
      };
    in
    {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
    configure = {
      packages.myNvimPackage = with pkgs.vimPlugins; {
        start = [
          (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
          comment-nvim
          editorconfig-vim
          lsp-colors-nvim
          lualine-nvim
          lush-nvim
          nvim-autopairs
          nvim-lspconfig
          nvim-treesitter-context
          nvim-treesitter-textobjects
          settings
          snippets-nvim
          telescope-nvim
          telescope-zf-native 
          toggleterm-nvim
          tokyonight-nvim
          trouble-nvim
          typescript-vim
          vim-better-whitespace
          vim-cue
          vim-dadbod
          vim-easy-align
          vim-eunuch
          vim-fugitive
          vim-lastplace
          vim-nix
          vim-repeat
          vim-rsi
          vim-surround
          vim-terraform
          vim-vinegar
          zig-vim
        ];
        opt = [];
      };
    };
  };
}
