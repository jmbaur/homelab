{ ... }: {
  networking.hostName = "test-vm";
  users.users.root.password = "";
  microvm = {
    hypervisor = "qemu";
    mem = 2048;
    vcpu = 2;
    shares = [{
      tag = "ro-store";
      source = "/nix/store";
      mountPoint = "/nix/.ro-store";
    }];
  };
}
