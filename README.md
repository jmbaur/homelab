# My NixOS configs

## Encrypted root setup

Assumptions:

- The device installing NixOS on is /dev/sda.
- A gpg card is readily available.

```bash
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 512MiB 100% # soon-to-be luks device
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB # boot partition
parted /dev/sda -- set 2 esp on

dd if=/dev/urandom of=disk.key bs=4096 count=1 # create key file

cryptsetup luksFormat --key-file=disk.key /dev/sda1 # use key file to create luks device
cryptsetup luksOpen --key-file=disk.key /dev/sda1 cryptlvm # use key file to open luks device

# LVM stuff
pvcreate /dev/mapper/cryptlvm
vgcreate vg /dev/mapper/cryptlvm
lvcreate -L 8G -n swap vg # create 8GB swap space
lvcreate -l '100%FREE' -n root vg # use rest for root

# Format & mount partitions
mkfs.ext4 -L root /dev/vg/root
mkswap -L swap /dev/vg/swap
mkfs.vfat -F 32 -n boot /dev/sda2
mount /dev/vg/root /mnt
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot
swapon /dev/vg/swap # optional

# Generate base NixOS config
nixos-generate-config --root /mnt

# GPG stuff
nix-shell -p gnupg
# Do these things:
#   gpg --card-edit
#   fetch
#   quit
gpg --encrypt --output=disk.key.gpg --recipient=jaredbaur@fastmail.com disk.key # encrypt key file
mv disk.key.gpg /mnt/etc/nixos
curl -OL https://keybase.io/jaredbaur/pgp_keys.asc
mv pgp_keys.asc /mnt/etc/nixos
shred -u disk.key

# NixOS stuff
uuid=$(blkid -s UUID /dev/sda1 | cut -d\" -f2)
echo << EOF
# Put this in your /etc/nixos/hardware-configuration.nix
services.udev.packages = [ pkgs.yubikey-personalization ];
boot.initrd.luks = {
  gpgSupport = true;
  devices.cryptlvm = {
    allowDiscards = true;
    device = "/dev/disk/by-uuid/${uuid}";
    preLVM = true;
    gpgCard = {
      publicKey = ./pgp_keys.asc;
      encryptedPass = ./disk.key.gpg;
      gracePeriod = 30; # seconds
    };
  };
};
EOF
nixos-install
reboot
```

## Hostnames

List from https://www.vegetables.co.nz/vegetables-a-z/.

### Taken

- Asparagus - Apareka/Pikopiko Pākehā
- Beetroot - Rengakura
- Broccoli - Pūpihi/Poroki
- Kale and Cavolo Nero
- Okra
- Rhubarb - Rūpapa

### Available

- Artichokes, globe - Atihoka
- Artichokes, Jerusalem - Atihoka
- Asian greens
- Beans - Pine/Pīni
- Brussels sprouts - Aonanī
- Cabbages - Kāpeti
- Capsicums - Rapikama
- Carrots - Uhikaramea/Kāreti
- Cauliflower - Puānīko/Pūputi/Kareparāoa
- Celeriac
- Celery - Tutaekōau/Hereri/Herewī
- Chilli peppers
- Chokos
- Courgettes and Scallopini - Roroa iti
- Cucumber - Kūkamo
- Eggplant
- Fennel - Taru haunga
- Garlic - Kārika
- Ginger - Tinitia
- Indian vegetables - Īniana huawhenua
- Kohlrabi - Okapi/Kara-rapi
- Kūmara - Kūmara
- Leeks - Riki/Rikiroa
- Microgreens
- Mushrooms - Harore
- Onions - Riki/Aniana
- Parsnips - Tāmore mā/Uhitea
- Peas, snow peas, sugar snap peas - Pī
- Potatoes - Rīwai
- Potatoes, purple - Taewa/Riwai
- Pūhā/Rauriki
- Radishes - Uhikura
- Salad greens
- Silverbeet - Kōrare
- Spinach - Rengamutu/Kōkihi
- Spring onions
- Sprouted beans and seeds - Pihi pīni
- Swedes - Tuwīti tānapu
- Sweet corn - Kānga
- Taro - Taro
- Tomatoes - Tōmato
- Turnips - Kotami
- Watercress - Wātakirihi
- Witloof
- Yams - Uwhiuwhi
- Lettuce - Rētehi
- Pumpkins - Paukena
- Fresh herbs, flowers - e.g. Tāima, Pāhiri, Pāhiri
- Melons - Merengi 
- Shallots
- Turmeric
