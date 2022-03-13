{ config, lib, pkgs, ... }: {
  custom.common.enable = true;
  custom.deploy.enable = true;

  zramSwap = {
    enable = true;
    swapDevices = 1;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  networking = {
    hostName = "rhubarb";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
  };

  environment.systemPackages = with pkgs; [
    ansible
    deploy-rs.deploy-rs
    git
    terraform
  ];

  nix.buildMachines = [{
    hostName = "kale";
    systems = [ "x86_64-linux" "aarch64-linux" ];
    maxJobs = 1;
    speedFactor = 2;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [ ];
  }];
  nix.distributedBuilds = true;
  # Speeds things up by downloading dependencies remotely:
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';

  users.users.jared = {
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [ (import ../../data/jmbaur-ssh-keys.nix) ];
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$HvZQftB0alLgxWLr$0NevK6oxPmOdjX.YuPjdgoCV0d5Ca8f/3uccn/WkNownDcT9fRbSwPuaID4AO0NubE0NfBrJR4eRKT/6Zgc4L0";
  };

  programs.ssh = {
    knownHostsFiles = [
      (pkgs.writeText "known_hosts" ''
        localhost ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCkVEJGrPKl7svCbNAIZjq7hnxHw/k7UeZeYdBaxwTJ2fJq27kAbzI6+CqEpSUeehxEZGPsbarZwqisBWKJlBrnlYcx3EFs1/uAW15j1ul42jYUwPYi9bOQWgtanMKP6jYM9BXeW2TkjA+wQppT1FtHcMPZ5hHmRei7MLq0n8I7yKFd/DT243f29srpxIdEFRCGfY8VqulGJch9BT1UIIB6+j4kRrYFgKr3XtGQOgEAMqXpZ7Nz/3qCjHsq6t9kOfb7H5ZwC3y52xHgkgiV2o7D2cOGeB3Nt7XOVYS5JAtcWH6K6LT9v0LJC3p7kCmHxZvuU20/6t+62ibKpvYm9cvizT6/951QPXBvZB2+s+yPFTTJtPsSqus5Di6EoiaVeFcRbZNCUsLR7+PvYkRDXxRhWqhKr2rE6GEfOTJlcLpZ9n43ZywReKvREGn6kW9fFcrggEdAmNW4nebC5pr3n136whhDrjCAKKRUmWj6f2kuSLLr+qR0DH9fef35z4jd6gauLvDMYyPECppy0YLP6EFlHggJr1CSfN0Sn4bNOSQ9up0qbEz0IDDj2NZAploTw58Kyqx19HaiKDQ65XPgvESCnqrvNdX1xw+kEAvm2Tg2G8uVyiASqWPgOy3+qODMi7szVRb3gwc0JmmtQObhwC/kfoxnLAHIG8owlVRUVBBwQ==
        localhost ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBlm0BNtFQdL0YNwdFyT/pW7a3RDLeH/w+ckx14aEwfO
        kale ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINSDTqHc9WfeZxTL97QzcmNAGUP/Qt2J5h3q1OqOvIen
        kale ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiamAf2qQSBbkyZIc9BJkrcbXg8wcqbBABe6SocaldjJUTslc5zaZfWPbeBwVDYrUv7My09U1QhKBeVx2oFlSTqjT4iKIxcGslgOnLJhtL0AATUC1r6KkyyCWV1F46YRtrb6eXvEhsxxAtQJDWu0ooRUHY/mfK/UAtJ1Kc3WfDZ8m1RfX21nENb9dmvwCUQdfQvg7jmHf7KEXTpySrg3ixcD4/Ns160u2FrlvaSYwkOlQygw+u80VVFflXC1xB3XkAhnR8I4IUsp9kegGt4A+9yYY3ADoH3UC4b1jWRMxNCcHsnuEzVN578TqsRNXDZA7TlhSp0Ube6YqzDNeBhlwQdCPFJFsIPLdDHhcF7CMKlOL1rjyxa0Tyff5oWL0XulA+D2R3t90e/rFutyeXy6TAKntx+HIl7d4DGInVFw76bKN+z7PhT+RrTObRgDIfafHw6kp8drXvRWN8Jr9mLUh3XV5r3qIUxVN9x0ONBdBV+6HJN//YieYLVCxxo5SDHgYwKHv5/86QxD5aXVT3UTL6np5fe2AdebZLlCkdtb4wxmxFNelZeh0k39dsu1u5gT19q/YvxuoQhGl21OWBZGF3mo1iNsamKMrISi873I7Xt5/xlPc5Idpr50RCdndF52TK4gHAU7U+gCMhBu8LCmu/A3gCqrX1+LX3BXQdqeAtdw==
        broccoli ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG5CvQypTDJ1jl+6/xBw7DLITOCzIwZRZIAefI3+uV6M
        broccoli ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCQpy9S183AAnOzgGDQpCScnfdokhM6TSKcD+A//pIaNcPUgiKoRaTdphc5Fv9RVgHPxz8+mJlGYGgIqMWLufV3EJaKLeWZo0AiivWnZtmTtT8kZNPqXa6O10/3rfwfWtFThBDc2uKnLzE5LBO4pvzbk34kyemSmgwRDIBbJfNgWI/1LUpzIKGPHTGUjBRp39ktK2LFNcYtAF9ofwiHY0e/sQDWug7P4FahOaATH5UOxpSl9PbyUHrvM5G7LIJZ1uTWFqNIb0rMuGfDkyQs8+1tbgE8CgLN3wD2sTFE/6LypLoLpAA3R61HmRwwlYJlcPaxpK2YBjAqx+58JEmnkss3EqZG003FJf8C7E+HlB+2W1kBDgIFe/K0yUxm3VNvMvEwN53Cryj85be8Rm9mnAbPIJgKibFPGZLqmu3GrTJcraS2BK3oW9MF//4y8j4lFLAzlOyhLGuEa5/2R8OhPj8Y9Rq3KMJ+cbYb1m2eMcrZe5ziq56pe1lKDINzGGrway5ycYu9CGPnZeIYW/USTYfnu/E7Cl6MP0Pwza8Z3xtL652pN8Ksd3GU16SwZAJp/1QL6iBAgKV6QqX7NqfRL3SiqS8ajsgps3QGgw6vHnfvFYeiCGcyaaMI9qACJSsuor/t8vnMMIjlQ+ULXC+0bNlTdtFZSYjZdKnEc1Ivj1dJ8Q==
      '')
    ];
    extraConfig = ''
      Host localhost kale broccoli
        User root
        IdentitiesOnly yes
        IdentityFile /etc/ssh/ssh_host_ed25519_key
    '';
  };
}
