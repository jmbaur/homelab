{
  emacs-nox,
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
  emacs = (emacsPackagesFor emacs-nox).withPackages (
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
      nix-mode
      projectile
      rg
      rust-mode
      zig-mode
    ]
  );
in
symlinkJoin {
  name = lib.appendToName "with-tools" emacs;
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
