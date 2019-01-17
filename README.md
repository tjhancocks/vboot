# vboot
vboot is a custom bootloader for the Veracyon Project. The purpose of the 
bootloader is to prepare and get the system into a known good configuration
for _vkernel_, as well as determine chipset specific information that can then
be provided to the kernel.

vboot currently assumes an i386 environment.

### File Systems
Currently vboot supports only a single "file system". This is a "raw" disk, in
which the kernel and modules are placed sequentially on the disk with limited
meta data pointing to their locations.

Eventually vboot will support the 
[Simple File System](https://wiki.osdev.org/wiki/SFS), and potentially others.


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
