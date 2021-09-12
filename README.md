Steps for a new host:

1. Install NixOS (https://nixos.org/manual/nixos/stable/index.html#ch-installation)
1. Reboot into new installation and `cd /etc/nixos`
1. `sudo chown -R $(whoami):users .`
1. `git init .`
1. `git remote add origin https://github.com/jmbaur/nixos-configs`
1. `git branch -M main`
1. `git pull origin main`
1. `cp ./configuration.nix ./hosts/${HOSTNAME}/configuration.nix`
1. Change imports in `./hosts/${HOSTNAME}/configuration.nix` to point to correct hardware-configuration.nix
1. Change imports in `./configuration.nix` to just import `./hosts/${HOSTNAME}/configuration.nix`
1. Commit changes and `git push --set-upstream origin main`


# Hostnames

List from https://www.vegetables.co.nz/vegetables-a-z/.

## Taken

- Beetroot - Rengakura
- Okra

## Available

- Artichokes, globe - Atihoka
- Artichokes, Jerusalem - Atihoka
- Asian greens
- Asparagus - Apareka/Pikopiko Pākehā
- Beans - Pine/Pīni
- Broccoli - Pūpihi/Poroki
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
- Kale and Cavolo Nero
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
- Rhubarb - Rūpapa
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
