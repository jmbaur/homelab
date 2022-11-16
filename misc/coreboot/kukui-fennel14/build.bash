# shellcheck shell=bash

# https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/master/sys-boot/libpayload/files/configs/config.kukui
cat >payloads/libpayload/configs/config.kukui <<EOF
CONFIG_LP_CHROMEOS=y
CONFIG_LP_ARCH_ARM64=y
CONFIG_LP_8250_SERIAL_CONSOLE=y
CONFIG_LP_TIMER_MTK=y
CONFIG_LP_USB_EHCI=y
CONFIG_LP_USB_XHCI=y
CONFIG_LP_USB_XHCI_MTK_QUIRK=y
EOF

make
make -C payloads/external/depthcharge BOARD=kukui

./build/cbfstool build/coreboot.rom add -f payloads/external/depthcharge/depthcharge/build/depthcharge.elf -t "simple elf" -n depthcharge
./build/cbfstool build/coreboot.rom print

cp build/coreboot.rom /out/coreboot.rom
