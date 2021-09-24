{ ref }:
builtins.fetchGit {
  url = "https://github.com/nix-community/home-manager.git";
  ref = ref;
}
