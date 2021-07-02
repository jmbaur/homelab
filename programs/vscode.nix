{ options, pkgs, ... }: {
  home-manager.users.jared.programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;
    extensions = with pkgs.vscode-extensions; [
      ms-vsliveshare.vsliveshare
      esbenp.prettier-vscode
      vscodevim.vim
      golang.Go
    ];
  };
}
