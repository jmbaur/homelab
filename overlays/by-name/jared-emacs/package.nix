{
  buildEnv,
  clang-tools,
  dts-lsp,
  emacs-pgtk,
  fd,
  fennel-ls,
  fnlfmt,
  go-tools,
  gofumpt,
  gopls,
  lua-language-server,
  nixd,
  nixfmt,
  pyright,
  ripgrep,
  ruff,
  rust-analyzer,
  rustfmt,
  shellcheck,
  shfmt,
  stdenv,
  tex-fmt,
  texlab,
  texlive,
  tofu-ls,
  ttags,
  zig_0_16,
  zls_0_16,
}:

let
  emacs = emacs-pgtk.pkgs.withPackages (epkgs: [
    (
      if stdenv.hostPlatform.isDarwin then
        epkgs.vterm
      else
        (epkgs.ghostel.overrideAttrs (old: {
          packageRequires = [ epkgs.evil ];
          preBuild = (old.preBuild or "") + ''
            cp extensions/evil-ghostel/evil-ghostel.el lisp
          '';
        }))
    )
    epkgs.company
    epkgs.direnv
    epkgs.dts-mode
    epkgs.evil
    epkgs.evil-collection
    epkgs.evil-commentary
    epkgs.evil-numbers
    epkgs.evil-surround
    epkgs.exec-path-from-shell
    epkgs.fennel-mode
    epkgs.geiser
    epkgs.git-link
    epkgs.go-mode
    epkgs.goto-chg
    epkgs.haskell-mode
    epkgs.janet-mode
    epkgs.lua-mode
    epkgs.magit
    epkgs.markdown-mode
    epkgs.meson-mode
    epkgs.monroe
    epkgs.nix-mode
    epkgs.racket-mode
    epkgs.rg
    epkgs.rust-mode
    epkgs.slime
    epkgs.sops
    epkgs.terraform-mode
    epkgs.typescript-mode
    epkgs.zig-mode
  ]);
in
buildEnv {
  name = "jared-emacs";
  meta.mainProgram = "emacs";
  paths = [
    clang-tools
    dts-lsp
    emacs
    fd
    fennel-ls
    fnlfmt
    go-tools
    gofumpt
    gopls
    lua-language-server
    nixd
    nixfmt
    pyright
    ripgrep
    ruff
    rust-analyzer
    rustfmt
    shellcheck
    shfmt
    tex-fmt
    texlab
    texlive.pkgs.latexmk
    tofu-ls
    ttags
    zig_0_16
    zls_0_16
  ];
}
