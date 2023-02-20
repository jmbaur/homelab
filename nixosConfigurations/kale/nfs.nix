{ config, lib, ... }:
let
  wg = import ../www/wg.nix;
  nfsDir = "/srv/nfs";
  nfsGitDir = "/srv/nfs/git";
  gitDir = "/var/lib/git";
in
{
  networking.firewall.allowedTCPPorts = [ 111 2049 20048 ];

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
    exports =
      let
        nfsGitClient = wg.www.ip;
        allClients = [ nfsGitClient ];
      in
      ''
        ${nfsDir}     ${lib.concatMapStringsSep " " (client: "${client}(rw,fsid=0,no_subtree_check)") allClients}
        ${nfsGitDir}  ${nfsGitClient}(rw,nohide,insecure,no_subtree_check)
      '';
  };
}
