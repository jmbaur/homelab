let
  artichoke = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILjBT83uxaXY9aa7IetgGpVKt5Mg1VP5fuXKM74o6jvA";
  kale = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINSDTqHc9WfeZxTL97QzcmNAGUP/Qt2J5h3q1OqOvIen";
  yubikey5cnfc = "age1yubikey1q20xxhpyk00m3ezajg3769jpmgwkvasq4dzutg75jq96fytnlcmxs9ltmga";
  yubikey5nfc = "age1yubikey1q0tf5gp52t3smx6zduwyjnurw4cgjlqdm58a9dj6430e8mtrfexfg586p8p";
  yubikeys = [ yubikey5nfc yubikey5cnfc ];
in
{
  "ipwatch.age".publicKeys = yubikeys ++ [ artichoke ];
  "pixel.age".publicKeys = yubikeys ++ [ artichoke ];
  "beetroot.age".publicKeys = yubikeys ++ [ artichoke ];
  "wg-trusted.age".publicKeys = yubikeys ++ [ artichoke ];
  "wg-iot.age".publicKeys = yubikeys ++ [ artichoke ];
  "wg-work.age".publicKeys = yubikeys ++ [ artichoke ];
  "capac.age".publicKeys = yubikeys;
}
