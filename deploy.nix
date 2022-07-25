inputs: with inputs; {
  nodes = {
    broccoli = {
      hostname = "broccoli.mgmt.home.arpa";
      profiles.system = {
        sshUser = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.broccoli;
      };
    };

    okra = {
      hostname = "okra.trusted.home.arpa";
      profiles.system = {
        sshUser = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.okra;
      };
    };

    asparagus = {
      hostname = "asparagus.mgmt.home.arpa";
      profiles.system = {
        sshUser = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.asparagus;
      };
    };

    kale = {
      hostname = "kale.mgmt.home.arpa";
      profiles.system = {
        sshUser = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.kale;
      };
    };

    kale2 = {
      hostname = "kale2.mgmt.home.arpa";
      profiles.system = {
        sshUser = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos
          self.nixosConfigurations.kale2;
      };
    };

    artichoke = {
      hostname = "artichoke.mgmt.home.arpa";
      profiles.system = {
        sshUser = "root";
        path = deploy-rs.lib.aarch64-linux.activate.nixos
          self.nixosConfigurations.artichoke;
      };
    };

    rhubarb = {
      hostname = "rhubarb.mgmt.home.arpa";
      profiles.system = {
        sshUser = "root";
        path = deploy-rs.lib.aarch64-linux.activate.nixos
          self.nixosConfigurations.rhubarb;
      };
    };
  };
}
