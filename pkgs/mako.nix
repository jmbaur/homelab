self: super: {
  mako = super.mako.overrideAttrs
    (old: {
      version = "aafbc91";
      src = super.fetchFromGitHub {
        owner = "emersion";
        repo = "mako";
        rev = "197ce76fa1066d2f48578d54ea152d908191a31c";
        sha256 = "sha256-Y6xs5KB30h2A+XRS1CxkMKUV6hBkNKjSmSHpib1zVYg=";
      };
    });
}
