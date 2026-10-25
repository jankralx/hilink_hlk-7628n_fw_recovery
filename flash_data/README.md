# Flash dumps (local only)

Full 32 MB reads of the W25Q256 SPI flash of HLK-7628N modules, made with
flashrom on a Raspberry Pi. They contain vendor firmware and per-module data
(MAC addresses), so `*.bin` files here are not committed (see `.gitignore`).

Flash layout (same in the Hi-Link firmware and in OpenWrt):

| Offset | Size | Partition | Contents |
|---|---|---|---|
| 0x000000 | 0x30000 | u-boot | bootloader |
| 0x030000 | 0x10000 | u-boot-env | bootloader settings |
| 0x040000 | 0x10000 | factory | MAC addresses (0x04, 0x28, 0x2e), Wi-Fi calibration |
| 0x050000 | rest | firmware | kernel + root filesystem |

Across all valid dumps, `factory` differs only in the MAC addresses and the
bytes 0x58–0x5a (per-module calibration). Everything else in it is identical.

## Files

| File | Read | Valid | Module | Contents |
|---|---|---|---|---|
| `w25q256_backup.bin` | 2025-12-18 22:21 | yes | the bricked module, first read after the brick | see below |
| `w25q256_ondra.bin` | 2025-12-18 22:22 | **no** | same module, read with a wrong SPI clock | random data, matches nothing, do not use |
| `w25q256_ondra2.bin` | 2025-12-18 23:04 | yes | a working module delivered with OpenWrt, used as the source to recover the bricked module | U-Boot 1.1.3 (May 23 2020), OpenWrt kernel 6.6.93 |
| `w25q256_original_fw.bin` | 2026-02-11 | yes | a module delivered with Hi-Link firmware | U-Boot 1.1.3 (Nov 24 2020), Hi-Link `HLK76x8` firmware |
| `w25q256_original_openwrt.bin` | 2026-07-09 | yes | a module delivered with Hi-Link's OpenWrt | U-Boot 1.1.3 (May 23 2020), OpenWrt kernel 3.10.14 |

"Valid" means that the kernel image at 0x50000 passes its header and data
CRC checks, and that the U-Boot and `factory` regions have the expected
structure.

## The bricked module (`w25q256_backup.bin`)

The module came with Hi-Link firmware. An OpenWrt image was uploaded through
the Hi-Link web update page, and the module did not start again.

The dump shows that almost nothing was damaged:

- 0x00000–0x0ffff (first erase block of U-Boot): erased, then 20768 bytes
  (0x0000–0x511f) of unknown, random-looking data written, the rest 0xff.
  This destroyed the start of U-Boot, so the module cannot start at all.
- 0x10000–0x2ffff (rest of U-Boot): byte-identical to `w25q256_original_fw.bin`
  (the same U-Boot build, Nov 24 2020).
- `factory`: intact, the module's own MAC.
- `firmware`: the Hi-Link firmware, CRC valid, plus its configuration
  (JFFS2) at 0xce0000.

So the update page wrote a ~20 KB file over the start of the bootloader.
Restoring the first 64 KB block of U-Boot from `w25q256_original_fw.bin`
would return the module exactly to its delivered state:

```sh
cp w25q256_backup.bin repaired.bin
dd if=w25q256_original_fw.bin of=repaired.bin bs=64k count=1 conv=notrunc
```

The module was recovered by writing `w25q256_ondra2.bin`, the dump of a
working module. If the whole image was written, the recovered module now has
the other module's `factory` (same MAC address). Its own `factory` is still
in `w25q256_backup.bin` and can be written back with
`flashrom ... -l hlk-7628n.layout -i factory -w w25q256_backup.bin`.
