{ pkgs, configs, ... }:
{
  nixpkgs.overlays = [
    (
      self: super: {
        weechat = super.weechat.override {
          configure = { availablePlugins, ... }: {
            scripts = with super.weechatScripts; [
              weechat-matrix
              wee-slack
            ];
          };
        };
      }
    )
  ];
  environment.systemPackages = [ pkgs.weechat ];
}
