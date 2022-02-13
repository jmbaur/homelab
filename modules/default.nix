{ overlays ? [ ] }: {
  imports = [
    ./common
    ./deploy
    ./desktop
    ./home
    ./virtualisation
  ];

  nixpkgs.overlays = overlays;
}
