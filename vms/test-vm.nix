{ ... }: {
  networking.hostName = "test-vm";
  users.users.root.password = "";
  microvm = {
    mem = 1024;
    vcpu = 2;
  };
}
