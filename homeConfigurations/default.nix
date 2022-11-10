inputs: with inputs; {
  jared = home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs {
      system = "aarch64-linux";
      overlays = [
        self.overlays.default
        git-get.overlays.default
        gobar.overlays.default
        gosee.overlays.default
        pd-notify.overlays.default
        self.overlays.default
      ];
    };
    modules = [
      ../modules/home-manager
      ({ pkgs, ... }: {
        custom.dev.enable = true;
        home.username = "jared";
        home.homeDirectory = "/home/jared";
        home.packages = [ pkgs.home-manager ];
      })
    ];
  };
}
