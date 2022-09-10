let
  artichoke = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILjBT83uxaXY9aa7IetgGpVKt5Mg1VP5fuXKM74o6jvA";
  kale = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINSDTqHc9WfeZxTL97QzcmNAGUP/Qt2J5h3q1OqOvIen";
  okra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG2aH4NxR8qoF4AOxKlz2HhCWaxJ+dGbcFVjITKtpG++";
  www = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM4DMaEcCRR9pFkEnCYKz7MwELDXwfHl9M6Ib9rYrS8A";
  yubikey5cnfc = "age1yubikey1q20xxhpyk00m3ezajg3769jpmgwkvasq4dzutg75jq96fytnlcmxs9ltmga";
  yubikey5nfc = "age1yubikey1q0tf5gp52t3smx6zduwyjnurw4cgjlqdm58a9dj6430e8mtrfexfg586p8p";
  yubikeys = [ yubikey5nfc yubikey5cnfc ];
  withYubikeys = keys: keys ++ yubikeys;
in
{
  "beetroot.age".publicKeys = withYubikeys [ artichoke ];
  "capac.age".publicKeys = yubikeys;
  "htpasswd.age".publicKeys = withYubikeys [ www ];
  "ipwatch.age".publicKeys = withYubikeys [ artichoke ];
  "okra.age".publicKeys = withYubikeys [ artichoke ];
  "pam_u2f_authfile.age".publicKeys = withYubikeys [ okra ];
  "pixel.age".publicKeys = withYubikeys [ artichoke ];
  "wg-iot.age".publicKeys = withYubikeys [ artichoke ];
  "wg-trusted.age".publicKeys = withYubikeys [ artichoke ];
  "wg-work.age".publicKeys = withYubikeys [ artichoke ];
}
