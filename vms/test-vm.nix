{ ... }: {
  networking.hostName = "test-vm";
  users.mutableUsers = false;
  users.users.jared.openssh.authorizedKeys.keyFiles = [ (import ../data/jmbaur-ssh-keys.nix) ];
  microvm = {
    hypervisor = "qemu";
    mem = 2048;
    vcpu = 2;
    shares = [{
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }];
    interfaces = [{
      type = "bridge";
      id = "qemu";
      bridge = "br-trusted";
      mac = "BB:EC:AF:8A:B2:E7";
    }];
  };
}
