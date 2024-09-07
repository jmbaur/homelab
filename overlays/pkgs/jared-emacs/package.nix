{
  emacs29-pgtk,
  emacsPackagesFor,
  gopls,
  lib,
  nil,
  nixfmt-rfc-style,
  rust-analyzer,
  symlinkJoin,
  zls,
}:
let
  emacs = (emacsPackagesFor emacs29-pgtk).withPackages (
    epkgs: with epkgs; [
      clipetty
      company
      envrc
      evil
      evil-collection
      evil-commentary
      evil-surround
      go-mode
      magit
      markdown-mode
      meson-mode
      nix-mode
      projectile
      python-mode
      rg
      rust-mode
      zig-mode
    ]
  );
in
symlinkJoin {
  name = lib.appendToName "with-tools" emacs;
  meta.mainProgram = "emacs";
  paths =
    [ emacs ]
    ++ [
      zls
      rust-analyzer
      gopls
      nil
      nixfmt-rfc-style
    ];
}
