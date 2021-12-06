{ pkgs, ... }:
{
  nixpkgs.overlays = [

    (import ./alacritty.nix)
    # (import ./chromium.nix)
    # (import ./foot.nix)
    (import ./i3status-rust)
    # (import ./kanshi.nix)
    (import ./kitty.nix)
    # (import ./mako.nix)
    # (import ./slack.nix)
    (import ./zig.nix)
    (import ./zls.nix)
    (import ./nix-direnv.nix)

    (self: super: {
      fdroidcl = super.callPackage ./fdroidcl.nix { };
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
