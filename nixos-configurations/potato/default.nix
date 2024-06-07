{ ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.kernelParams = [ "console=ttyS0,115200" ];

  tinyboot = {
    enable = true;
    board = "fizz-fizz";
  };

  services.navidrome = {
    enable = true;
    settings = {
      Address = "[::]";
      Port = 4533;
    };
  };

  custom.basicNetwork.enable = true;

  custom.image = {
    enable = true;
    mutableNixStore = true; # TODO(jared): make false
    boot.bootLoaderSpec.enable = true;
    installer.targetDisk = "/dev/nvme0n1"; # TODO(jared): be more specific
  };
}
