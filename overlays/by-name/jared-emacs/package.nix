{ emacs-nox }:
emacs-nox.pkgs.withPackages (
  epkgs: with epkgs; [
    compile-angel
    evil
    evil-collection
    evil-commentary
    evil-numbers
    evil-surround
    geiser
    magit
    nix-mode
    slime
    vterm
    zig-mode
  ]
)
