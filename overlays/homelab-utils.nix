{
  binutils,
  buildPackages,
  chickenPackages_6,
  lib,
  makeWrapper,
  stdenv,
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
    hash = "sha256-uz7IAdE+zBdJGvwKI/xY3dEcc/A7dgWCA/BPCEaFaNI=";
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

      nativeBuildInputs = [
        binutils
        zig_0_16
      ];

      __structuredAttrs = true;
      separateDebugInfo = true;
      strictDeps = true;
      doCheck = true;

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

      postConfigure = ''
        ln -sf ${deps} $ZIG_GLOBAL_CACHE_DIR/p
      '';

      passthru = { inherit deps; };
      meta = {
        inherit platforms;
        mainProgram = name;
      };
    };

  # Plain make rather than eggDerivation, since chicken-install can't cross.
  mkChickenTool =
    {
      name,
      eggs ? _: [ ],
      platforms ? lib.platforms.all,
    }:
    let
      repo = "lib/chicken/${toString chickenPackages_6.chicken.binaryVersion}";
      hostEggs = eggs chickenPackages_6.chickenEggs;
    in
    stdenv.mkDerivation {
      pname = name;
      inherit version;

      src = lib.fileset.toSource {
        root = root + /src;
        fileset = lib.fileset.unions [
          (root + /src/Makefile)
          (root + /src/${name}.scm)
        ];
      };

      # Build-platform eggs provide import libraries, host ones are loaded at runtime.
      nativeBuildInputs = [
        buildPackages.chickenPackages_6.chicken
        makeWrapper
      ]
      ++ eggs buildPackages.chickenPackages_6.chickenEggs;
      buildInputs = [ chickenPackages_6.chicken ] ++ hostEggs;

      __structuredAttrs = true;
      separateDebugInfo = true;
      strictDeps = true;
      enableParallelBuilding = true;

      # The setup hook points the build chicken at host import libs.
      preBuild = ''
        unset CHICKEN_REPOSITORY_PATH
        for p in "''${pkgsBuildHost[@]}"; do
          if [ -d "$p/${repo}" ]; then
            addToSearchPath CHICKEN_REPOSITORY_PATH "$p/${repo}"
          fi
        done
        export CHICKEN_REPOSITORY_PATH
      '';

      postInstall = lib.optionalString (hostEggs != [ ]) ''
        eggPath=
        for p in "''${pkgsHostTarget[@]}"; do
          if [ -d "$p/${repo}" ]; then
            addToSearchPath eggPath "$p/${repo}"
          fi
        done
        wrapProgram $out/bin/${name} --prefix CHICKEN_REPOSITORY_PATH : "$eggPath"
      '';

      makeFlags = [
        "PROGRAMS=${name}"
        "PREFIX=${placeholder "out"}"
        "CHICKEN_PREFIX=${lib.getDev chickenPackages_6.chicken}"
      ];

      meta = {
        inherit platforms;
        mainProgram = name;
      };
    };
in
lib.attrsets.unionOfDisjoint
  (lib.mapAttrs (name: args: mkChickenTool ({ inherit name; } // args)) {
    copy.eggs = eggs: [ eggs.base64 ];
    macgen.eggs = eggs: [ eggs.srfi-1 ];
    nix-key.eggs = eggs: [
      eggs.base64
      eggs.libsodium
    ];
    nixos-kexec = {
      platforms = lib.platforms.linux;
      eggs = eggs: [ eggs.srfi-13 ];
    };
    pomo = { };
  })
  (
    lib.mapAttrs (name: args: mkTool ({ inherit name; } // args)) {
      homelab-backup-recv = { };
      homelab-garage-door = {
        extraSrc = [ (root + /src/garage-door.html) ];
        platforms = lib.platforms.linux;
      };
      networkd-dhcpv6-client-prefix = { };
      pb = { };
    }
  )
