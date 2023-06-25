{ config, lib, pkgs, ... }:
let
  fileModule = { config, name, ... }: {
    options = with lib; {
      text = mkOption {
        type = types.nullOr types.lines;
        default = null;
      };
      source = mkOption {
        type = types.path;
      };
    };

    config = lib.mkIf (config.text != null) {
      source = pkgs.writeText (builtins.baseNameOf name) config.text;
    };
  };

  userModule = { ... }: {
    options = with lib; {
      file = mkOption {
        type = types.attrsOf (types.submodule fileModule);
        default = { };
      };
    };
  };
in
{
  options = with lib; {
    users.users = mkOption {
      type = types.attrsOf (types.submodule userModule);
    };
  };

  config = {
    system.userActivationScripts.file = lib.concatLines (lib.mapAttrsToList
      (_: { name, file, ... }:
        let
          trackedFiles = pkgs.writeText "${name}-tracked-files" (lib.concatLines (lib.mapAttrsToList (path: _: path) file));
        in
        ''
          if [[ $USER == ${name} ]]; then
            if [[ -f ~/.tracked-files ]]; then
              # only show diff from left-hand file
              for stale_link in $(${pkgs.diffutils}/bin/diff --changed-group-format="%<" --unchanged-group-format="" ~/.tracked-files ${trackedFiles}); do
                rm ~/''${stale_link}
              done
            fi

            ${lib.concatLines (lib.mapAttrsToList (path: { source, ... }: ''
              if [[ $(realpath ~/${path}) != ${trackedFiles} ]]; then
                dir=$(dirname ${path})
                if [[ ! -d $dir ]]; then
                  mkdir -p $dir
                fi
                ln -sf ${source} ~/${path}
              fi
            '') file)}

            if [[ $(realpath ~/.tracked-files) != ${trackedFiles} ]]; then
              ln -sf ${trackedFiles} ~/.tracked-files
            fi
          fi
        '')
      (lib.filterAttrs (_: user: user.isNormalUser) config.users.users));
  };
}
