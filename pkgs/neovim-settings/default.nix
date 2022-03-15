{ vimUtils }:
vimUtils.buildVimPlugin {
  name = "personal-settings";
  src = builtins.path { path = ./.; };
}
