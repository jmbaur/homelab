{ config, lib, pkgs, ... }:
let
  cfg = config.custom.deployer;
in
with lib;
{
  options.custom.deployer = {
    enable = mkEnableOption "this machine to deploy to other machines";
    authorizedKeyFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
    };
  };
  config = mkIf cfg.enable {
    # Must be able to bootstrap the deployer, allow SSH access to the
    # deployer by personal keys.
    assertions = [{
      assertion = (cfg.authorizedKeyFiles != [ ]);
      message = "No authorized keys configured for deployer";
    }];
    users.users.deploy = {
      uid = 2000;
      isNormalUser = true;
      description = "Deployer";
      packages = [ pkgs.deploy-rs ];
      openssh.authorizedKeys.keyFiles = cfg.authorizedKeyFiles;
    };
    system.activationScripts.deployer.text = ''
      # Make sure we don't write to stdout, since in case of
      # socket activation, it goes to the remote side (#19589).
      exec >&2

      path="${config.users.users.deploy.home}/.ssh"
      mkdir -m 0755 -p "$path"

      keyfile="''${path}/id_ed25519"
      if ! [ -s "$keyfile" ]; then
      rm -f "$keyfile"
      ${pkgs.openssh}/bin/ssh-keygen \
      -C "${config.users.users.deploy.name}@${config.networking.hostName}" \
      -t "ed25519" \
      -f "$keyfile" \
      -N ""
      fi

      chown -R ${toString config.users.users.deploy.uid}:${config.users.users.deploy.group} "$path"
    '';
  };
}
