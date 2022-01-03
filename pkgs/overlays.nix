{ extraOverlays ? [], ... }:
{
  nixpkgs.overlays = [

    (import ./alacritty.nix)
    (import ./dunst.nix)
    (import ./foot.nix)
    (import ./i3status-rust)
    (import ./kanshi.nix)
    (import ./kitty.nix)
    (import ./mako.nix)
    (import ./nix-direnv.nix)
    (import ./slack.nix)
    (import ./vscode.nix)
    (import ./xsecurelock.nix)
    (import ./zig.nix)
    (import ./zls.nix)

    (self: super: {
      fdroidcl = super.callPackage ./fdroidcl.nix { };
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

  ] ++ extraOverlays;
}
