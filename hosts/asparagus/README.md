Run `wpa_passphrase '<name>' '<password>'` to fill out secrets.nix:

```nix
{ ... }: { networking.wireless.networks.<name>.pskRaw = "pskraw"; }
```
