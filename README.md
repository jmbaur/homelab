Steps for a new host:

1. Install NixOS (https://nixos.org/manual/nixos/stable/index.html#ch-installation)
1. Reboot into new installation and `cd /etc/nixos`
1. `sudo chown -R <user>:users .`
1. `git init .`
1. `git remote add origin https://github.com/jmbaur/nixos-configs`
1. `git branch -M main`
1. `git pull origin main`
1. `cp ./configuration.nix ./hosts/<hostname>/configuration.nix`
1. Change imports in `./hosts/<hostname>/configuration.nix` to point to correct hardware-configuration.nix
1. Change imports in `./configuration.nix` to just import `./hosts/<hostname>/configuration.nix`
1. Commit changes and `git push --set-upstream origin main`
