self: super: {
  mako = super.mako.overrideAttrs
    (old: {
      version = "aafbc91";
      src = super.fetchFromGitHub {
        owner = "emersion";
        repo = "mako";
        rev = "aafbc91da038e5a6ebab67a66a644487db3410d7";
        sha256 = "sha256-Q3Gqg4iAbS+YJLdU8niiOfFqIQq+RL4O7SUz0elQfA8=";
      };
    });
}
