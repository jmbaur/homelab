{ pkgs, ... }:
{
  imports = [
    ./router.nix
    ./web.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  hardware.bpi-r3.enable = true;

  users.users.root.openssh.authorizedKeys.keyFiles = [ pkgs.jmbaur-ssh-keys ];

  hardware.deviceTree.overlays = [
    {
      name = "real-time-clock";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "bananapi,bpi-r3";
        };

        &i2c0 {
          rtc@68 {
              compatible = "nxp,pcf8523";
              reg = <0x68>;
              quartz-load-femtofarads = <7000>;
          };
        };
      '';
    }
  ];

  custom.wgNetwork.nodes.cauliflower = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  custom.image = {
    installer.targetDisk = "/dev/disk/by-path/platform-11230000.mmc";
    boot.uboot = {
      enable = true;
      kernelLoadAddress = "0x50000000";
      bootMedium.type = "mmc";
    };
  };
}
