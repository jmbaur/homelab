inputs:
inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:
  pkgs.treefmt.withConfig {
    runtimeInputs = [
      pkgs.nixfmt-rfc-style
      pkgs.shfmt
      pkgs.stylua
      pkgs.zig_0_14
    ];

    settings = {
      on-unmatched = "info";

      formatter.nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
      };

      formatter.shell = {
        command = "shfmt";
        includes = [
          "*.sh"
          "*.bash"
        ];
      };

      formatter.stylua = {
        command = "stylua";
        includes = [ "*.lua" ];
      };

      formatter.zig = {
        command = "zig";
        options = [ "fmt" ];
        includes = [ "*.zig" ];
      };
    };
  }
) inputs.self.legacyPackages
