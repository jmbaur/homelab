{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    bc
    vim
    tmux
    git
    curl
    htop
    atop
    tcpdump
    iperf3
    dnsutils
    iputils
    traceroute
    dmidecode
    killall
    lm_sensors
    renameutils
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  environment.sessionVariables = { EDITOR = "vim"; };

  programs = {
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID5KAKAW5h57PPAJsR9B8VA/KpZoJvsldS+jsDyNk9QA"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOTuM+py6p17ysZ3UXJHvwPZip58/+aGHKqbcKJlkbbA4wOOsWhlEhtunX139mNUoU9TtlzlcmlbAsAqP7Z05srOghO71Z48UqO5X7fnN3bP6k8/3FagYI1+JJs29Tp7bvKvjk+GT5AAiTW5cXaiWBkJ42wMJHi1CTI23V96U9TJA0suAkCYFie/cL0pWYljBCog3yrH8y629+p2IFNcIsHMcV0LvHmMQet5p4Cxg08+FX8nVWa+ZnpKNAEJ6M2Z84S4MKMiZ22MIqK4PeGEAesoeZ7PmDFEuE0STwiZ1IHkFoCj5Z/0hl2b0roQbzsoaklN2Sv8T+KfpD48TqEqCRozn6J5jqwq7dzKKr7HVUDSw+jjMzSSZKLr2CGoe790ljZTpHjftUyEO8OhuVh7jhbPEaPwikkqgvFBLdhL0uv3o4avs5vVxkpBpgjWCip1Z14iRjEWgxfOcPjS6LLs9IkgrUkTKvGAl+rhtqV6oZekYGjGxWN5UdMwfcmGijYhE="
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDpm0hFuBneaRKMreFG4niss8ybc041JBeZXI1VaIKG8UyA4p68PCjNOf7mjyDva3T2mNdB71drIMJTgUKIfOA5hI9BCfQUNKavjz9CnfPfdTFrKmR6E0Aj8GZ15BNDbLjjpgm3CxwcJ3tDm4QkfAa3MwwjlCj2vCJeJw8nVBSPxGcVKDkKC8Z8YygHujy4voVIljAGfoZrzgKg3iZuq+YoSwenjlfR0E3v3VefbEFn7F+RNQr9lazqIhEYcH29Y0C6OP+DldUtBSfow/8BGfGVB/8xYZnLb0AbQP7O3EcpBnIcKxShQv+ikopLYp4w1nCZ0iKCwgrvHGkueYwn4rmgrv7/q9R6Tqplnk450Cn4Q8Tfqou7Fzn0MKxAMJUQ1xOdtrlbj21Iy1av6RB3D0Tpy0m/Ol03Pg8GJYSi5alVsi6Dk8Wjq37TJYjdk/y59hXFjWTQokcJh8cjBg3YdlcH2LIsJ0anOJMJ7CypC8g6aMvJQcDcWfFNyB2PEfDwv20="
    ];
  };

  environment.binsh = "${pkgs.dash}/bin/dash";

  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
}
