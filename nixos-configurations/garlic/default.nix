{ pkgs, ... }: {
  nixpkgs.hostPlatform = "aarch64-linux";

  boot.initrd.availableKernelModules = [ "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  virtualisation.hypervGuest.enable = true;

  custom.dev.enable = true;
  custom.users.jared.enable = true;
  custom.basicNetwork.enable = true;

  custom.image = {
    enable = true;
    mutableNixStore = true;
    primaryDisk = "/dev/sda";
    hasTpm2 = true;
    postImageCommands = ''
      ${pkgs.vmTools.qemu}/bin/qemu-img convert -f raw -o subformat=dynamic -O vhdx image.raw $out/image.vhdx
      rm image.raw
    '';
  };
}
