{
  buildPackages,
  chickenPackages_6,
  lib,
  makeWrapper,
  stdenv,
}:

let
  root = ../.;

  version = "0.0.0";

  # Plain make rather than eggDerivation, since chicken-install can't cross.
  mkChickenTool =
    {
      name,
      eggs ? _: [ ],
      extraSrc ? [ ],
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
        fileset = lib.fileset.unions (
          [
            (root + /src/Makefile)
            (root + /src/${name}.scm)
          ]
          ++ extraSrc
        );
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
lib.mapAttrs (name: args: mkChickenTool ({ inherit name; } // args)) {
  copy.eggs = eggs: [ eggs.base64 ];
  homelab-backup-recv = {
    extraSrc = [ (root + /src/homelab-backup-recv.h) ];
    platforms = lib.platforms.linux;
    eggs = eggs: [
      eggs.simple-logger
      eggs.srfi-18
    ];
  };
  homelab-garage-door = {
    extraSrc = [ (root + /src/garage-door.html) ];
    platforms = lib.platforms.linux;
    eggs = eggs: [
      eggs.gpiocdev
      eggs.intarweb
      eggs.simple-logger
      eggs.spiffy
      eggs.srfi-18
      eggs.uri-common
    ];
  };
  macgen.eggs = eggs: [ eggs.srfi-1 ];
  networkd-dhcpv6-client-prefix.eggs = eggs: [
    eggs.srfi-1
    eggs.srfi-13
    eggs.srfi-180
  ];
  nix-key.eggs = eggs: [
    eggs.base64
    eggs.libsodium
  ];
  nixos-kexec = {
    platforms = lib.platforms.linux;
    eggs = eggs: [ eggs.srfi-13 ];
  };
  pb.eggs = eggs: [
    eggs.http-client
    eggs.intarweb
    eggs.openssl
    eggs.qrencode
    eggs.srfi-180
    eggs.uri-common
  ];
  pomo = { };
}
