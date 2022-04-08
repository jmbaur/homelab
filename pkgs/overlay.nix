final: prev: {
  fdroidcl = prev.callPackage ./fdroidcl.nix { };
  c2esp = prev.callPackage ./c2esp.nix { };
  dmenu =
    let
      border = builtins.fetchurl {
        url = "https://tools.suckless.org/dmenu/patches/border/dmenu-border-20201112-1a13d04.diff";
        sha256 = "1ghckggwgasw9p87x900gk9v3682d6is74q2rd0vcpsmrvpiv606";
      };
      center = builtins.fetchurl {
        url = "https://tools.suckless.org/dmenu/patches/center/dmenu-center-20200111-8cd37e1.diff";
        sha256 = "0x7jc1m0138p7vfa955jmfhhyc317y0wbl8cxasr6cfpq8nq1qsg";
      };
      lineHeight = builtins.fetchurl {
        url = "https://tools.suckless.org/dmenu/patches/line-height/dmenu-lineheight-5.0.diff";
        sha256 = "1dllfy9yznjcq65ivwkd77377ccfry72jmy3m77ms6ns62x891by";
      };
      highlight = builtins.fetchurl {
        url = "https://tools.suckless.org/dmenu/patches/highlight/dmenu-highlight-20201211-fcdc159.diff";
        sha256 = "09iz07wzz4nk8z8psqxdhbx2ldbg0h15h5615prb6aggk2b8mya2";
      };
    in
    prev.dmenu.override {
      patches = [
        border
        center
        highlight
        lineHeight
      ];
    };
  st =
    let
      anysize = builtins.fetchurl {
        url = "https://st.suckless.org/patches/anysize/st-anysize-0.8.4.diff";
        sha256 = "1w3fjj6i0f8bii5c6gszl5lji3hq8fkqrcpxgxkcd33qks8zfl9q";
      };
      ringbuffer = builtins.fetchurl {
        url = "https://st.suckless.org/patches/scrollback/st-scrollback-ringbuffer-0.8.5.diff";
        sha256 = "0xxwgkgpzc7s8ad0pgcwhm5hqyh2wy56a9yrxid68xm0np2g6m5h";
      };
      scrollbackMouse = builtins.fetchurl {
        url = "https://st.suckless.org/patches/scrollback/st-scrollback-mouse-20220127-2c5edf2.diff";
        sha256 = "0xjg9gyd3ag68srhs7fsjs8yp8sp2srhmjq7699i207bpz6rpb26";
      };
      boxdraw = builtins.fetchurl {
        url = "https://st.suckless.org/patches/boxdraw/st-boxdraw_v2-0.8.3.diff";
        sha256 = "0n4n83mffxp8i0c2hfaqabxbqz0as2yxx8v8ll76gxiihqa1hhd2";
      };
    in
    prev.st.override {
      patches = [
        # boxdraw
        anysize
        ringbuffer
        scrollbackMouse
      ];
    };
  j = prev.callPackage ./j.nix { };
  zf = prev.callPackage ./zf.nix { };
  # https://github.com/cdown/clipmenu/issues/142
  clipmenu = prev.clipmenu.overrideAttrs (old: {
    version = "b30c01dbe3c8f1a13191cafb5171708ee80ef7d5";
    src = prev.fetchFromGitHub {
      repo = "clipmenu";
      owner = "cdown";
      rev = "b30c01dbe3c8f1a13191cafb5171708ee80ef7d5";
      sha256 = "17mpl7jbywy4k0smsw1f7z87nagkw1ssdq1y3wa5n5hmbv27mp8r";
    };
  });
}
