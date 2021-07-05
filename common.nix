{ config, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    tmux
    git
    curl
    htop
    nixfmt
    tcpdump
    iperf3
    dnsutils
    iputils
    dmidecode
    killall
    lm_sensors
    (vim_configurable.customize {
      name = "vim";
      vimrcConfig.packages.myplugins = with pkgs.vimPlugins; {
        start = [ vim-nix vim-lastplace fugitive commentary surround ];
        opt = [ ];
      };
      vimrcConfig.customRC = ''
        set nocompatible
        set backspace=indent,eol,start
        color elflord
        set hidden
        set noswapfile
        set sw=2 ts=2 et
        set colorcolumn=80 
      '';
    })
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  programs = {
    vim.defaultEditor = true;
    tmux = {
      enable = true;
      terminal = "screen-256color";
      keyMode = "vi";
      clock24 = true;
      baseIndex = 1;
      shortcut = "a";
      newSession = true;
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
