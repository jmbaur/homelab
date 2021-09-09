{ config, lib, pkgs, ... }: {
  imports = [
    "${
      builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }
    }/lenovo/thinkpad"
    "${
      builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }
    }/common/cpu/intel"
    "${
      builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }
    }/common/gpu/nvidia.nix"
    "${
      builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; }
    }/common/pc/laptop/acpi_call.nix"
  ];
}
