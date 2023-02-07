inputs: with inputs;
nixpkgs.lib.genAttrs
  [ "aarch64-linux" "x86_64-linux" ]
  (system:
  let
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
    };
    mkApp = program: { type = "app"; inherit program; };
  in
  {
    bootstrap-beetroot = {
      type = "app";
      program =
        let
          program = pkgs.writeShellApplication {
            name = "bootstrap-beetroot";
            runtimeInputs = with pkgs; [ yq-go ];
            text = builtins.readFile ../nixosConfigurations/beetroot/bootstrap.bash;
          };
        in
        "${program}/bin/bootstrap-beetroot";
    };
    bitwarden-bemenu = mkApp "${pkgs.bitwarden-bemenu}/bin/bitwarden-bemenu";
    cicada = mkApp "${pkgs.cicada}/bin/cicada";
    coredns-keygen = mkApp "${pkgs.coredns-utils}/bin/coredns-keygen";
    discord-webapp = mkApp "${pkgs.discord-webapp}/bin/discord-webapp";
    flarectl = mkApp "${pkgs.flarectl}/bin/flarectl";
    flashrom-cros = mkApp "${pkgs.flashrom-cros}/bin/flashrom";
    flashrom-dasharo = mkApp "${pkgs.flashrom-dasharo}/bin/flashrom";
    ixio = mkApp "${pkgs.ixio}/bin/ixio";
    j = mkApp "${pkgs.j}/bin/j";
    macgen = mkApp "${pkgs.macgen}/bin/macgen";
    mirror-to-x = mkApp "${pkgs.mirror-to-x}/bin/mirror-to-x";
    mkdepthcharge = mkApp "${pkgs.depthcharge-tools}/bin/mkdepthcharge";
    neovim = mkApp "${pkgs.neovim}/bin/nvim";
    outlook-webapp = mkApp "${pkgs.outlook-webapp}/bin/outlook-webapp";
    slack-webapp = mkApp "${pkgs.slack-webapp}/bin/slack-webapp";
    spotify-webapp = mkApp "${pkgs.spotify-webapp}/bin/spotify-webapp";
    teams-webapp = mkApp "${pkgs.teams-webapp}/bin/teams-webapp";
    u-root = mkApp "${pkgs.u-root}/bin/u-root";
    v4l-show = mkApp "${pkgs.v4l-show}/bin/v4l-show";
    wip = mkApp "${pkgs.wip}/bin/wip";
    yamlfmt = mkApp "${pkgs.yamlfmt}/bin/yamlfmt";
  })
