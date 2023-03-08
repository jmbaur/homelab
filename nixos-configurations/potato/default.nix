{ modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/netboot/netboot-minimal.nix" ];
  boot.kernelParams = [ "console=ttyS2,15625000" ];
  system.stateVersion = "23.05";
}
