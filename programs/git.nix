{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    aliases = {
      st = "status --short --branch";
      di = "diff";
      br = "branch";
      co = "checkout";
      lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
    };
    delta.enable = true;
    delta.options.syntax-theme = "Solarized (dark)";
    ignores = [ "*~" "*.swp" ];
    userEmail = "jaredbaur@fastmail.com";
    userName = "Jared Baur";
    extraConfig = { pull = { rebase = false; }; "credential \"https://github.com\"" = { helper = "\!${pkgs.gh}/bin/gh auth git-credential"; }; };
  };

}
