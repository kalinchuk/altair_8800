# Altair 8800 Dual IDE V4 Board

This directory contains code and instructions on booting an Altair 8800 from an IDE drive. More details can be found on [YouTube](https://www.youtube.com/watch?v=lt8m1Byoukw).

![528EF698-481A-42D2-A0EA-F420E8707A3B_1_201_a](https://github.com/kalinchuk/altair_8800/assets/1035984/264cc08d-063c-4383-a567-435029366e9b)

## Instructions

1. Purchase and assemble the [Dual IDE V4 board](http://www.s100computers.com/My%20System%20Pages/IDE%20Board/My%20IDE%20Card.htm). You can find the assembly video at https://www.youtube.com/watch?v=-n2ctWLwP5c
2. Configure the Dual IDE V4 board to use the correct I/O address. Set the 16 bit I/O address range to 00xH by jumpering K5 to 1-2 (the top two positions). Set switch SW2 positions 1-8 to closed. Set switch SW1 to 30-34H by having the switches (left to right): open, closed, closed, open, open, closed, closed, closed. Jumper K1 to 1-2 (the top two positions).
3. Either connect a real IDE drive to the board or use a [Compact Flash drive](https://amzn.to/3uIuUFI). If using compact flash, make sure to use the lower footprint for P4 and P5 to accomdate a [CF to IDE adapter](https://amzn.to/49ygaYZ). Use a [CF to USB adapter](https://amzn.to/3P1Yuwz) to flash the CF drive.
4. The bootloader assumes that you're using the [88-2SIOJP serial board](https://deramp.com/2SIOJP.html) that is configured to use 10xH and 11xH I/O addresses.
5. Either assemble the IDEBOOT.asm file or use the pre-assembled IDEBOOT.bin or IDEBOOT.hex to either 1. copy to the Altair 8800 using AMON (see video) or 2. program an EPROM with it (see video). If programming an EPROM, use an [EPROM programmer](https://amzn.to/3SVbTI0).
6. The bootloader assumes that it will run from address F000xH so, if using an EPROM, be sure the configure it to start at that address. Also, ensure that 64K of RAM is available or modify the bootloader to support less RAM.

### CF Drive Flashing

```
diskutil list ; find the disk path for the CF Drive
diskutil unmountDisk /dev/disk4
sudo dd if=/path/to/binaryfile.bin of=/dev/disk4 bs=1m
```


## Notes

* The bootloader can be improved by running at address 0 so that it's independent of the RAM size. The downsize of doing so is that programs that are booted with it will not be able to start at address 0 (unless the bootloader is moved elsewhere on start).
