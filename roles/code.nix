{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # programming utilities
    direnv
    nix-direnv
    fd
    gh
    tig
    ripgrep
    skopeo
    buildah
    podman-compose
  ];

  environment.pathsToLink = [ "/share/nix-direnv" ];

  # So GC doesn't clean up nix shells
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  virtualisation = {
    podman.enable = true;
    podman.dockerCompat = true;
    containers.enable = true;
    containers.containersConf.settings = {
      engine = { detach_keys = "ctrl-e,ctrl-q"; };
    };
  };

}
