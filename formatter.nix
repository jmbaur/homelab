inputs:
inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:
  pkgs.treefmt.withConfig {
    runtimeInputs = [
      pkgs.nixfmt
      pkgs.shfmt
      pkgs.stylua
      pkgs.zig_0_15
    ];

    settings = {
      on-unmatched = "info";

      formatter.nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
      };

      formatter.shell = {
        command = "shfmt";
        options = [
          "-w"
          "-s"
        ];
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
