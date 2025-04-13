{
  emacs30-pgtk,
  emacsPackagesFor,
  gopls,
  lib,
  nil,
  nixfmt-rfc-style,
  pyright,
  rust-analyzer,
  symlinkJoin,
  zls,
}:
let
  emacs = (emacsPackagesFor emacs30-pgtk).withPackages (
    epkgs: with epkgs; [
      cmake-mode
      company
      envrc
      evil
      evil-collection
      evil-commentary
      evil-numbers
      evil-surround
      go-mode
      magit
      markdown-mode
      meson-mode
      nix-mode
      orderless
      projectile
      python-mode
      rg
      rust-mode
      vertico
      vterm
      zig-mode
    ]
  );
in
symlinkJoin {
  name = lib.appendToName "with-tools" emacs;
  meta.mainProgram = "emacs";
  paths = [
    emacs
    gopls
    nil
    nixfmt-rfc-style
    pyright
    rust-analyzer
    zls
  ];
}
