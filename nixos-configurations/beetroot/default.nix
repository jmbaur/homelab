{ lib, ... }: {
  imports = [
    (import ../disko-single-disk-encrypted.nix "/dev/nvme0n1")
    ./minimal.nix
  ];

  hardware.bluetooth.enable = true;

  zramSwap.enable = true;

  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices.cryptroot.crypttabExtraOpts = lib.mkForce [ "tpm2-device=auto" ];

  fileSystems."/".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/nix".options = [ "noatime" "discard=async" "compress=zstd" ];
  fileSystems."/home".options = [ "noatime" "discard=async" "compress=zstd" ];

  custom = {
    dev.enable = true;
    gui.enable = true;
    laptop.enable = true;
    users.jared.enable = true;
    remoteBuilders.aarch64builder.enable = false;
    wg-mesh = {
      enable = false;
      peers.squash.dnsName = "squash.jmbaur.com";
    };
  };

  nix.settings = {
    # substituters = [ "http://carrot.home.arpa" ];
    # trusted-public-keys = [ "carrot.home.arpa:dxp2PztB2LlcVufzgvhsrM9FvrDJcRvP2SqMXr3GSt8=" ];
    # fallback = true;
  };
}
