{ config, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    bc
    tmux
    git
    curl
    htop
    nixfmt
    tcpdump
    iperf3
    dnsutils
    iputils
    traceroute
    dmidecode
    killall
    lm_sensors
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz";
    }))
  ];

  programs = {
    # packages needed for language servers:
    #   gcc
    #   haskell-language-server
    #   nodePackages.typescript-language-server
    #   nodePackages.bash-language-server
    #   gopls
    #   rnix-lsp
    #   pyright
    #   tree-sitter
    #   nodejs
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
      configure = {
        packages.myPlugins = with pkgs.vimPlugins; {
          start = [
            vim-lastplace
            vim-nix
            typescript-vim
            vim-commentary
            vim-fugitive
            vim-surround
            vim-repeat
            vim-rsi
            nvim-treesitter
            nvim-treesitter-textobjects
            nvim-lspconfig
            telescope-nvim
            popup-nvim
            plenary-nvim
            nvim-autopairs
          ];
          opt = [ ];
        };
        customRC = builtins.readFile ./programs/init.vim;
      };
    };
    tmux = {
      enable = true;
      terminal = "screen-256color";
      keyMode = "vi";
      escapeTime = 10;
      clock24 = true;
      baseIndex = 1;
      shortcut = "a";
      newSession = true;
      secureSocket = true;
      extraConfig = ''
        set -g renumber-windows on
        set -g update-environment "SSH_AUTH_SOCK SSH_CONNECTION"
        set-option -sa terminal-overrides ',xterm-256color:RGB'
        bind-key b set-option status
        bind-key / command-prompt "split-window 'exec man %%'"
        bind-key S command-prompt "new-window -n %1 'ssh %1'"
      '';
    };
  };

  users.users.jared = {
    isNormalUser = true;
    home = "/home/jared";
    description = "Jared Baur";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKU/J9T/6BwzloIiXP5wCkgkJbSl5B3z+c6Z/J3baa/u"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOTuM+py6p17ysZ3UXJHvwPZip58/+aGHKqbcKJlkbbA4wOOsWhlEhtunX139mNUoU9TtlzlcmlbAsAqP7Z05srOghO71Z48UqO5X7fnN3bP6k8/3FagYI1+JJs29Tp7bvKvjk+GT5AAiTW5cXaiWBkJ42wMJHi1CTI23V96U9TJA0suAkCYFie/cL0pWYljBCog3yrH8y629+p2IFNcIsHMcV0LvHmMQet5p4Cxg08+FX8nVWa+ZnpKNAEJ6M2Z84S4MKMiZ22MIqK4PeGEAesoeZ7PmDFEuE0STwiZ1IHkFoCj5Z/0hl2b0roQbzsoaklN2Sv8T+KfpD48TqEqCRozn6J5jqwq7dzKKr7HVUDSw+jjMzSSZKLr2CGoe790ljZTpHjftUyEO8OhuVh7jhbPEaPwikkqgvFBLdhL0uv3o4avs5vVxkpBpgjWCip1Z14iRjEWgxfOcPjS6LLs9IkgrUkTKvGAl+rhtqV6oZekYGjGxWN5UdMwfcmGijYhE="
    ];
  };

  environment.binsh = "${pkgs.dash}/bin/dash";

  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
}
