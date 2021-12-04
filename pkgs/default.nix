{ pkgs, ... }:
{
  nixpkgs.overlays = [

    (import ./alacritty.nix)
    (import ./chromium.nix)
    (import ./foot.nix)
    (import ./i3status-rust)
    (import ./kanshi.nix)
    (import ./kitty.nix)
    (import ./mako.nix)
    (import ./slack.nix)
    (import ./zig.nix)
    (import ./zls.nix)

    (self: super: {
      nix-direnv = super.nix-direnv.override { enableFlakes = true; };
    })
    (self: super: {
      fdroidcl = super.callPackage ./fdroidcl.nix { };
    })

    (self: super: {
      gosee = super.callPackage ./gosee.nix { };
    })

    (self: super: {
      git-get = super.callPackage ./git-get.nix { };
    })

    (self: super: {
      bat = super.bat.overrideAttrs (old: {
        postInstall = ''
          wrapProgram $out/bin/bat --add-flags "--theme=gruvbox-dark"
        '';
      });
    })

    (self: super: {
      vscode-with-extensions = super.vscode-with-extensions.override {
        vscodeExtensions = with super.vscode-extensions; [
          ms-vsliveshare.vsliveshare
          vscodevim.vim
        ];
      };
    })

    (self: super: {
      start-recording = (super.callPackage ./recording.nix { }).start;
      stop-recording = (super.callPackage ./recording.nix { }).stop;
    })
    (self: super: {
      p = self.callPackage ./p.nix { };
    })
    (self: super: {
      pa-switch = super.callPackage ./pa-switch.nix { };
    })

  ];

}
