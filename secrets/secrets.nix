let
  yubikey5nfc = "age1yubikey1q0tf5gp52t3smx6zduwyjnurw4cgjlqdm58a9dj6430e8mtrfexfg586p8p";
  yubikey5cnfc = "age1yubikey1q20xxhpyk00m3ezajg3769jpmgwkvasq4dzutg75jq96fytnlcmxs9ltmga";
  yubikeys = [ yubikey5nfc yubikey5cnfc ];
  broccoli = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmz1b709FzbYy9uGsWTQDjC6B+mvz9zuyrg1GdJrNrQ";
  kale = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINSDTqHc9WfeZxTL97QzcmNAGUP/Qt2J5h3q1OqOvIen";
in
{
  "ipwatch.age".publicKeys = yubikeys ++ [ broccoli ];
  "pixel.age".publicKeys = yubikeys ++ [ broccoli ];
  "beetroot.age".publicKeys = yubikeys ++ [ broccoli ];
  "wg-trusted.age".publicKeys = yubikeys ++ [ broccoli ];
  "wg-iot.age".publicKeys = yubikeys ++ [ broccoli ];
  "capac.age".publicKeys = yubikeys;
}
