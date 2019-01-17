# Draft RawFS Specification
RawFS is an extremely rudimentary file system intended for boot media that will
never be written to by the booted environment. This is not to say that it can't
be written to. It is indended to be a light weight, minimal implementation to
assist with rapid development of _vboot_ and _vkernel_.

**It should never be used for a production environment!**

### Layout
The layout of RawFS is basic, and is illustrated below.

```
  
  +-----+-----+---------
  |  A  |  B  |   ...
  +-----+-----+---------

 	A : 512 byte bootsector
 	B : 512 byte meta-data block
 	C : Contiguous array of "files"

```

The bootsector is like any other bootsector. It should contain a BIOS Parameter
Block, and have a signature of `AA55` to allow the BIOS to recognise the disk as
bootable.

The Metadata Block is a binary blob of configuration specific information. It
has the following structure:

| Name        | Offset | Size |
| ----------- | ------ | ---- |
| boot_string | 0      | 32   |
| stage2_off  | 32     | 2    |
| stage2_len  | 34     | 2    |
| kernel_off  | 36     | 4    |
| kernel_len  | 38     | 4    |
| ramdisk_off | 42     | 4    |
| ramdisk_len | 46     | 4    |