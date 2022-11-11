inputs: with inputs; {
  default = nixpkgs.lib.composeManyExtensions [
    gosee.overlays.default
    (final: prev:
      let
        out-of-tree = prev.callPackage ./out-of-tree.nix { };
      in
      {
        inherit (out-of-tree)
          cicada
          coredns-utils
          flarectl
          xremap
          yamlfmt
          zf
          ;

        bitwarden-bemenu = prev.callPackage ./bitwarden-bemenu.nix { };
        j = prev.callPackage ./j.nix { };
        macgen = prev.callPackage ./macgen.nix { };
        mirror-to-x = prev.callPackage ./mirror-to-x.nix { };
        v4l-show = prev.callPackage ./v4l-show.nix { };
        wip = prev.writeShellScriptBin "wip" "git commit -am \"WIP\" && git push";
        ixio = prev.writeShellScriptBin "ixio" "${prev.curl}/bin/curl -F 'f:1=<-' ix.io";
        stevenblack-hosts = prev.linkFarm "hosts" (
          let
            repo = (prev.fetchgit {
              inherit (prev.lib.importJSON ./stevenblack_hosts.json)
                url rev sha256;
            });
          in
          [
            { name = "hosts"; path = "${repo}/hosts"; }
          ]
        );

        vimPlugins = prev.vimPlugins // {
          jmbaur-settings = prev.vimUtils.buildVimPlugin {
            pname = "jmbaur-settings";
            version = "0.0.0";
            src = ./neovim/settings;
          };
          smartyank-nvim =
            let
              smartyank-nvim-src = prev.lib.importJSON
                ./ibhagwan_smartyank-nvim.json;
            in
            prev.vimUtils.buildVimPlugin {
              pname = "smartyank-nvim";
              version = smartyank-nvim-src.rev;
              src = prev.fetchgit { inherit (smartyank-nvim-src) url sha256 rev; };
            };
        };
        neovim = prev.callPackage ./neovim { inherit (final) vimPlugins; };
        neovim-boring = prev.writeShellScriptBin
          "nvimb"
          ''exec -a "$0" ${final.neovim.override { boring = true; }}/bin/nvim "$@"'';

        mkWaylandVariant = prev.callPackage ./mkWaylandVariant.nix { };
        brave-wayland = final.mkWaylandVariant
          prev.brave;
        chromium-wayland = final.mkWaylandVariant
          prev.chromium;
        google-chrome-wayland = final.mkWaylandVariant
          prev.google-chrome;
        bitwarden-wayland = final.mkWaylandVariant
          prev.bitwarden;
        discord-wayland = final.mkWaylandVariant
          prev.discord;
        signal-desktop-wayland = final.mkWaylandVariant
          prev.signal-desktop;
        slack-wayland = final.mkWaylandVariant
          prev.slack;

        mkWebApp = prev.callPackage
          ./mkWebApp.nix
          { chromium = final.chromium-wayland; };
        discord-webapp = final.mkWebApp
          "discord"
          "https://discord.com/app";
        outlook-webapp = final.mkWebApp
          "outlook"
          "https://outlook.com";
        slack-webapp = final.mkWebApp
          "slack"
          "https://app.slack.com/client";
        spotify-webapp = final.mkWebApp
          "spotify"
          "https://open.spotify.com";
        teams-webapp = final.mkWebApp
          "teams"
          "https://teams.microsoft.com";

        grafana-dashboards = prev.callPackage ./grafana-dashboards { };

        ubootCN9130_CF_Pro = prev.callPackage ./ubootCN9130_CF_Pro.nix {
          inherit cn913x_build;
        };
        armTrustedFirmwareCN9130_CF_Pro = prev.callPackage ./armTrustedFirmwareCN9130_CF_Pro.nix {
          inherit (final) ubootCN9130_CF_Pro;
          inherit cn913x_build;
        };
        linux_cn913x = prev.callPackage ./linux_cn913x.nix {
          inherit cn913x_build;
        };

        jmbaur-keybase-pgp-keys = prev.fetchurl {
          url = "https://keybase.io/jaredbaur/pgp_keys.asc";
          sha256 = "0rw02akfvdrpdrznhaxsy8105ng5r8xb5mlmjwh9msf4brnbwrj7";
        };
        jmbaur-github-ssh-keys = prev.fetchurl {
          url = "https://github.com/jmbaur.keys";
          sha256 = "sha256-etDXRhTogpoCKA0kOcPYyyQohKQLYmf+YvbzqdJM0mg=";
        };
      })
  ];
}
