let
  artichoke = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILjBT83uxaXY9aa7IetgGpVKt5Mg1VP5fuXKM74o6jvA";
  carrot = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII/wPUH4ydU6OiLGIvrnyCUdQQweyVLXj71H2BJ0L9zu";
  kale = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6q44hTsu6FVYG5izJxymw33SZJRDMttHxrwNBqdSJl";
  okra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG2aH4NxR8qoF4AOxKlz2HhCWaxJ+dGbcFVjITKtpG++";
  rhubarb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJaYLZk4Eh0Yw/hjf57mnUffPt4fwzbtwnRaWAGPeX1";
  www = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4DMaEcCRR9pFkEnCYKz7MwELDXwfHl9M6Ib9rYrS8A";

  yubikey5cnfc = "age1yubikey1q20xxhpyk00m3ezajg3769jpmgwkvasq4dzutg75jq96fytnlcmxs9ltmga";
  yubikey5nfc = "age1yubikey1q0tf5gp52t3smx6zduwyjnurw4cgjlqdm58a9dj6430e8mtrfexfg586p8p";
  yubikeys = [ yubikey5nfc yubikey5cnfc ];
  withYubikeys = keys: keys ++ yubikeys;
in
{
  "capac.age".publicKeys = yubikeys;
  "htpasswd.age".publicKeys = withYubikeys [ www ];
  "ipwatch.age".publicKeys = withYubikeys [ artichoke ];
  "pam_u2f_authfile.age".publicKeys = withYubikeys [ carrot okra ];
  "webauthn-tiny-env.age".publicKeys = withYubikeys [ www ];
  "wg-iot-artichoke.age".publicKeys = withYubikeys [ artichoke ];
  "wg-iot-phone.age".publicKeys = withYubikeys [ artichoke ];
  "wg-public-artichoke.age".publicKeys = withYubikeys [ artichoke ];
  "wg-public-rhubarb.age".publicKeys = withYubikeys [ rhubarb ];
  "wg-public-kale.age".publicKeys = withYubikeys [ kale ];
  "wg-trusted-artichoke.age".publicKeys = withYubikeys [ artichoke ];
  "wg-trusted-beetroot.age".publicKeys = withYubikeys [ artichoke ];
  "wg-trusted-carrot.age".publicKeys = withYubikeys [ artichoke ];
}
