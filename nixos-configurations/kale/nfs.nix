{ config, ... }:
let
  wg = import ../../nixos-modules/mesh-network/inventory.nix;
  nfsGitDir = "/srv/nfs/git";
  gitDir = "/var/lib/git";
in
{
  fileSystems.${nfsGitDir} = {
    device = gitDir;
    options = [ "bind" ];
  };

  # git user required to exist on the nfs server
  users.users.git = {
    home = gitDir;
    uid = config.ids.uids.git;
    group = "git";
  };
  users.groups.git.gid = config.ids.gids.git;

  systemd.tmpfiles.rules = [
    "v ${config.fileSystems.${nfsGitDir}.device} - ${config.users.users.git.name} ${config.users.users.git.group} - -"
  ];

  services.nfs.server = {
    enable = true;
    exports = ''
      ${nfsGitDir} ${wg.www.ip}(rw,no_root_squash,no_subtree_check,fsid=0)
    '';
  };
}
