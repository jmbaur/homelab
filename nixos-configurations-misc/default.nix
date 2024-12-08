inputs: {
  DESKTOP-FA8MC26 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.self.nixosModules.default
      (
        { config, pkgs, ... }:
        {
          wsl = {
            enable = true;
            defaultUser = "jared";
          };
          networking.hostName = "DESKTOP-FA8MC26";
          users.users.${config.wsl.defaultUser} = {
            password = "";
            shell = pkgs.fish;
          };
          networking.nftables.enable = false; # https://github.com/microsoft/WSL/issues/6044
          systemd.sysusers.enable = false;
          custom.nativeBuild = true;
          custom.dev.enable = true;
          nixpkgs.hostPlatform = "aarch64-linux";
        }
      )
    ];
  };
}
