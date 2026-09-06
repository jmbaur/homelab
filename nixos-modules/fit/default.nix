{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatLines
    flatten
    mapAttrsToList
    mkOption
    toHexString
    types
    ;

  cfg = config.boot.fit;

  inherit (pkgs.stdenv.hostPlatform) qemuArch;
in
{
  options.boot.fit = {
    description = mkOption {
      type = types.str;
      default = config.system.nixos.distroId;
      defaultText = "config.system.nixos.distroId";
      description = ''
        FIT image description
      '';
    };

    loadAddress = mkOption {
      type = types.int;
      default = 0;
      description = ''
        The address the kernel will be loaded to, in physical memory.
      '';
    };

    kernel = mkOption {
      type = types.path;
      default = "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";
      defaultText = "\${config.boot.kernelPackages.kernel}/\${config.system.boot.loader.kernelFile}";
      description = ''
        Path to the Linux kernel Image.
      '';
    };

    initrd = mkOption {
      type = types.path;
      default = "${config.system.build.initialRamdisk}/initrd";
      defaultText = "\${config.system.build.initialRamdisk}/initrd";
      description = ''
        Path to the initrd for early boot.
      '';
    };

    dtb = {
      path = mkOption {
        type = types.path;
        default = "${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}";
        defaultText = "\${config.hardware.deviceTree.package}/\${config.hardware.deviceTree.name}";
        description = ''
          Path to the device tree blob used at boot.
        '';
      };

      modifications = mkOption {
        type = types.attrsOf (
          types.attrsOf (
            types.submodule {
              options.type = mkOption {
                type = types.enum [
                  "i"
                  "r"
                  "s"
                  "u"
                  "x"
                ];
              };
              options.value = mkOption { type = types.str; };
            }
          )
        );
        default = { };
        example = ''
          { "/chosen" = { version = "1.0.0"; }; }
        '';
        description = ''
          Modifications to be made to the devicetree file provided.
        '';
      };
    };
  };

  config = {
    boot.fit.dtb.modifications."/chosen" = {
      bootargs = {
        type = "s";
        value = ''"init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}"'';
      };
    };

    system.build.fitImage = pkgs.callPackage (
      {
        dtc,
        stdenvNoCC,
        ubootTools,
        xz,
      }:
      stdenvNoCC.mkDerivation {
        name = "fit-image";

        nativeBuildInputs = [
          dtc
          xz
          ubootTools
        ];

        env = {
          arch =
            {
              "aarch64" = "arm64";
              "i386" = "x86";
            }
            .${qemuArch} or qemuArch;
          kernelParams = toString config.boot.kernelParams;
          loadAddress = "0x${toHexString cfg.loadAddress}";
          inherit (cfg) description;
        };

        __structuredAttrs = true;
        unsafeDiscardReferences.out = true;

        buildCommand = ''
          install -m0644 ${cfg.kernel} kernel
          xz --format=lzma kernel

          install -m0644 ${cfg.initrd} initrd

          install -m0644 ${cfg.dtb.path} dtb

          ${concatLines (
            flatten (
              mapAttrsToList (
                path: modifications:
                mapAttrsToList (property: { type, value }: ''
                  fdtput --verbose --auto-path --type=${type} dtb ${path} ${property} ${value}
                '') modifications
              ) cfg.dtb.modifications
            )
          )}

          install -m0644 ${./kernel.its} fit.its
          substituteInPlace fit.its --subst-var loadAddress --subst-var arch --subst-var description

          mkdir -p $out
          mkimage -f fit.its $out/kernel.itb
        '';
      }
    ) { };
  };
}
