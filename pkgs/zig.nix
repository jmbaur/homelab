self: super: {
  zig = (super.callPackage
    (
      super.fetchFromGitHub {
        owner = "arqv";
        repo = "zig-overlay";
        rev = "84b12f2f19dd90ee170f4966429635beadd5b647";
        sha256 = "1q0cxpnf2x4nwwivmdl6d1il5xmz43ijcv082l77fbvcmk9hlvpy";
      })
    { }).master.latest;
}
