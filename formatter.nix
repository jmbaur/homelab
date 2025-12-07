inputs:
inputs.nixpkgs.lib.mapAttrs (
  _: pkgs:
  pkgs.treefmt.withConfig {
    runtimeInputs = [
      pkgs.deadnix
      pkgs.nixfmt
      pkgs.shellcheck
      pkgs.shfmt
      pkgs.statix
      pkgs.stylua
      pkgs.zig_0_15
    ];

    settings = {
      on-unmatched = "info";

      formatter.nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
      };

      formatter.deadnix = {
        command = "deadnix";
        includes = [ "*.nix" ];
        options = [ "--edit" ];
      };

      formatter.statix = {
        command = pkgs.writeShellScript "statix-fix" ''
          for file in "$@"; do
            statix fix "$file"
          done
        '';
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
          "*.envrc"
          "*.envrc.*"
        ];
      };

      formatter.shellcheck = {
        command = "shellcheck";
        includes = [
          "*.sh"
          "*.bash"
          "*.envrc"
          "*.envrc.*"
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
