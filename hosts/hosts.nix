{
  domain = "lan";
  router = {
    hostName = "atlas";
    # enp2s0
    ipAddress = "192.168.1.1";
  };
  hosts = {
    # Switch (GS308EP)
    switch = {
      hostName = "switch";
      ipAddress = "192.168.1.2";
      ethernetAddress = "94:a6:7e:69:99:3e";
    };
    # AP (NETGEAR9DD59F)
    ap = {
      hostName = "ap";
      ipAddress = "192.168.1.3";
      ethernetAddress = "9c:c9:eb:9d:d5:9f";
    };
    # HP EC200a server
    server = {
      hostName = "titan";
      ipAddress = "192.168.1.4";
      ethernetAddress = "14:02:ec:49:2c:c5";
    };
  };
}
