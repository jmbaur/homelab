{ emacs-nox }:
emacs-nox.pkgs.withPackages (
  epkgs: with epkgs; [
    compile-angel
    evil
    evil-commentary
    evil-numbers
    evil-surround
    geiser
    magit
    nix-mode
    slime
    zig-mode
  ]
)
