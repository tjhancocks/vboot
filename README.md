# vboot
vboot is a custom bootloader for the Veracyon Project. The purpose of the 
bootloader is to prepare and get the system into a known good configuration
for _vkernel_, as well as determine chipset specific information that can then
be provided to the kernel.

vboot currently assumes an i386 environment.

### Goals and Aims
vboot will be a fully multiboot 1 compliant bootloader. It will load an ELF 
based kernel, any required modules/ramdisks and configure the system depending
on what the kernel requires.

To begin with, there is a much stronger emphasis on getting it working for 
vkernel and the VeracyonOS project as a whole, and using RawFS (mentioned below)
for rapid development. However it will be expanded to support other filesystems
and a wider range of configuration options.

In the future I want to make sure it is UEFI compliant as well. BIOS is a 
deprecated technology and will be removed from Intel chips in the near future.
Currently vboot relies heavily on the BIOS for disk reading functions, but much
of this can come from UEFI itself. BIOS is currently being used as it is 
compatible with the legacy/older computers that I use as test benches for OSDev,
and for that reason I do not wish to drop BIOS support completely.

### File Systems
Currently vboot supports only a single "file system". This is a "raw" disk, in
which the kernel and modules are placed sequentially on the disk with limited
meta data pointing to their locations.

Eventually vboot will support the 
[Simple File System](https://wiki.osdev.org/wiki/SFS), and potentially others.

### Getting Started
To get started with vboot, you'll need to ensure you have all of the required 
tools to build and run the project. 

- `nasm` - This is the assembler used to build the bootloader itself
- `patch` - This is a binary patching tool I wrote available 
[here](https://github.com/tjhancocks/patch).
- `i686-elf-gcc` - A cross compiler with an x86 ELF target. This is to build the
test kernel, and is not essential.
- `bochs` - The test environment/emulator used for debugging the bootloader.

If you have each of these installed then to build the project all you need to
do is run `make` and a disk image will be produced with the bootloader 
installed. Currently the disk image is a RawFS floppy disk image. In time the 
default will likely change and customisation options will be added.

To test the bootloader you can run `make rawfs-test` and the same disk image 
will be produced and then launched inside BOCHS.

### Contributing
Contributions to vboot are welcome. Please fork the project, take a look at the
issues, make your additions and alterations, then fire a pull request back to 
the main repo. There is a lot of work to be done.

### License (MIT)

```
Copyright (c) 2019 Tom Hancocks

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
