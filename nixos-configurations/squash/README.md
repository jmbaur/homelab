# tinyboot

firmware image

```bash
# in u-boot
make clearfog_defconfig
echo -e "CONFIG_FIT=y\nCONFIG_SPL_FIT=y" >> .config
make olddefconfig
make -j$(nproc) $makeFlags

# here
nix build .#nixosConfigurations.squash.config.tinyboot.build.linux -o result-linux
nix build .#nixosConfigurations.squash.config.tinyboot.build.initrd -o result-initrd
```
