# shellcheck shell=bash

# https://chromium.googlesource.com/chromiumos/overlays/chromiumos-overlay/+/master/sys-boot/libpayload/files/configs/config.asurada
cat >payloads/libpayload/configs/config.asurada <<EOF
CONFIG_LP_CHROMEOS=y
CONFIG_LP_ARCH_ARM64=y
CONFIG_LP_8250_SERIAL_CONSOLE=y
CONFIG_LP_TIMER_MTK=y
CONFIG_LP_USB_EHCI=y
CONFIG_LP_USB_XHCI=y
CONFIG_LP_USB_XHCI_MTK_QUIRK=y
EOF

make

cp build/coreboot.rom /out/coreboot.rom
