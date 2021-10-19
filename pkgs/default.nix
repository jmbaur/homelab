{ config, lib, pkgs, ... }:
{
  nixpkgs.overlays =
    [
      (self: super: { efm-langserver = super.callPackage ./efm-langserver { }; })
      (self: super: { fdroidcl = super.callPackage ./fdroidcl { }; })
      (self: super: { gosee = super.callPackage ./gosee { }; })
      (self: super: { htmlq = super.callPackage ./htmlq { }; })
      (self: super: { pa-switch = super.callPackage ./pa-switch { }; })
      (self: super: { proj = super.callPackage ./proj { }; })
    ];
}
