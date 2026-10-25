#!/bin/sh
# Build a 32 MB flash image for the HLK-7628N from a U-Boot binary and an
# OpenWrt sysupgrade image. The factory region (MAC, Wi-Fi calibration) is
# left empty: write the result with hlk-7628n.layout and "-i u-boot -i firmware",
# so that the module keeps its own factory data.
#
#   ./mkflash.sh u-boot.bin openwrt-...-sysupgrade.bin flash.bin
set -e

[ $# -eq 3 ] || { echo "usage: $0 <u-boot.bin> <sysupgrade.bin> <output.bin>" >&2; exit 1; }
uboot=$1 firmware=$2 out=$3

[ "$(stat -c %s "$uboot")" -le $((0x30000)) ] || { echo "$uboot is larger than 192 KiB" >&2; exit 1; }
[ "$(stat -c %s "$firmware")" -le $((0x1fb0000)) ] || { echo "$firmware is too large" >&2; exit 1; }

# 32 MiB of 0xff (erased flash)
dd if=/dev/zero bs=1M count=32 status=none | tr '\0' '\377' > "$out"
dd if="$uboot" of="$out" conv=notrunc status=none
dd if="$firmware" of="$out" bs=64k seek=5 conv=notrunc status=none
echo "$out: u-boot at 0x0, firmware at 0x50000"
