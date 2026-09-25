{
  lib,
  stdenvNoCC,
  zig_0_16,
}:

let
  root = ../.;

  version = "0.0.0";

  # Shared by all tools so the dependencies are only fetched once.
  deps = zig_0_16.fetchDeps {
    pname = "homelab-utils";
    inherit version;
    src = lib.fileset.toSource {
      inherit root;
      fileset = lib.fileset.unions [
        (root + /build.zig)
        (root + /build.zig.zon)
      ];
    };
    fetchAll = true;
    hash = "sha256-Zh0cWmGqgjNlp0bx1OevzsgK+Ghf16+3j4HdBiF6piM=";
  };

  mkTool =
    {
      name,
      extraSrc ? [ ],
      platforms ? lib.platforms.all,
    }:
    stdenvNoCC.mkDerivation {
      pname = name;
      inherit version;

      src = lib.fileset.toSource {
        inherit root;
        fileset = lib.fileset.unions (
          [
            (root + /build.zig)
            (root + /build.zig.zon)
            (root + /src/${name}.zig)
          ]
          ++ extraSrc
        );
      };

      nativeBuildInputs = [ zig_0_16 ];

      __structuredAttrs = true;
      doCheck = true;
      dontPatchELF = true;
      dontStrip = true;
      strictDeps = true;

      zigBuildFlags = [
        "-Dtool=${name}"
        "-Dtarget=${stdenvNoCC.hostPlatform.qemuArch}-${
          {
            darwin = "macos";
            linux = "linux";
          }
          .${stdenvNoCC.hostPlatform.parsed.kernel.name}
        }"
      ];
      zigCheckFlags = [ "-Dtool=${name}" ];

      # TODO(jared): libsodium modifies downloaded contents at build time (this
      # should be fixed).
      postConfigure = ''
        cp -r ${deps} $ZIG_GLOBAL_CACHE_DIR/p
        chmod u+w --recursive $ZIG_GLOBAL_CACHE_DIR
      '';

      passthru = { inherit deps; };
      meta = {
        inherit platforms;
        mainProgram = name;
      };
    };

in
lib.mapAttrs (name: args: mkTool ({ inherit name; } // args)) {
  copy = { };
  homelab-backup-recv = { };
  homelab-garage-door = {
    extraSrc = [ (root + /src/garage-door.html) ];
    platforms = lib.platforms.linux;
  };
  macgen = { };
  networkd-dhcpv6-client-prefix = { };
  nix-key = { };
  nixos-kexec.platforms = lib.platforms.linux;
  pb = { };
  pomo = { };
}
