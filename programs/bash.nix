{ config, pkgs, ... }:
{
  programs.bash = {
    enable = true;
    enableVteIntegration = true;
    shellAliases = {
      ls = "exa";
      ll = "exa -hl";
      la = "exa -ahl";
      grep = "grep --color=auto";
    };
    initExtra = ''
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    '';
    bashrcExtra = ''
      eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
    '';
  };
}
