{ config, pkgs, ... }:

{
  home-manager.users.jared.programs.git = {
    enable = true;
    aliases = {
      st = "status -sb";
      br = "branch";
      di = "diff";
      lg = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
    };
    userEmail = "jaredbaur@fastmail.com";
    userName = "Jared Baur";
    extraConfig = {
      core.editor = "vim";
      github.user = "jmbaur";
      pull.rebase = false;
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      difftool.prompt = false;
    };
  };
}
