{ config, lib, ... }: {
  networking = {
    useDHCP = lib.mkForce false;
    hostName = "beetroot";
    wireless.iwd.enable = true;
    interfaces.enp3s0f0.useDHCP = true;
    interfaces.enp4s0.useDHCP = true;
    interfaces.wlan0.useDHCP = true;
    # wg-quick.interfaces.wg0 = {
    #   autostart = false;
    #   privateKeyFile = config.sops.secrets.wg0.path;
    #   address = [ "192.168.130.100" ];
    #   dns = [ "192.168.130.1" ];
    #   peers = [{
    #     publicKey = "68sZOobFSYwyt7ZVsQ6steLqHH/CEQQHluUr+X6y5AQ=";
    #     endpoint = "vpn.jmbaur.com:51830";
    #     allowedIPs = [ "0.0.0.0/0" "::/0" ];
    #   }];
    # };
  };
}
