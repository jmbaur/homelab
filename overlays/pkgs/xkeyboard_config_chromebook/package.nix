{ xkeyboard_config, fetchpatch }:

xkeyboard_config.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/GalliumOS/xkeyboard-config/10f5fe726c367ede4a89b2ef91a9366b15bcee4e/debian/patches/chromebook.patch";
      hash = "sha256-3LRIAez23P+zuAEfwLo/LiPc35rl+qhX/SBpvJgLHL8=";
    })
  ];
})
