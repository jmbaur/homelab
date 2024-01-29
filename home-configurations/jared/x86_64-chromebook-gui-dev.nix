{
  system = "x86_64-linux";
  modules = [{
    jared.gui = {
      enable = true;
      defaultXkbOptions = "ctrl:swap_lwin_lctl";
    };
    jared.dev.enable = true;
  }];
}
