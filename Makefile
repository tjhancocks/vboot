# Copyright (c) 2019 Tom Hancocks
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

################################################################################

ROOT = $(CURDIR)
BUILD = $(ROOT)/build

BUILD.RAWFS.stage1 = $(BUILD)/rawfs-stage1.bin
BUILD.RAWFS.stage2 = $(BUILD)/rawfs-stage2.bin
BUILD.RAWFS.disk = $(BUILD)/rawfs.img
BUILD.KERNEL.stub = $(BUILD)/stub-kernel
BUILD.RAMDISK = $(ROOT)/kernel/ramdisk
TOOL.bsize = $(ROOT)/tool/bsize/bsize.sh

TARGET.TRIPLET = i686-elf
TOOL.CC = $(shell which $(TARGET.TRIPLET)-gcc)
TOOL.LD = $(shell which $(TARGET.TRIPLET)-ld)
TOOL.AS = $(shell which nasm)

################################################################################

.PHONY: all
all: $(BUILD.RAWFS.disk)

.PHONY: clean
clean:
	-rm -rf $(BUILD)

.PHONY: stub-kernel
stub-kernel: $(BUILD.KERNEL.stub)

.PHONY: rawfs-test
rawfs-test: clean $(BUILD.RAWFS.disk)
	bochs -q "boot:a" "floppya: 1_44=$(BUILD.RAWFS.disk), status=inserted" \
		"magic_break: enabled=1" \
		 "com1: enabled=1, mode=file, dev=bochs.log" \
		 "memory: guest=256, host=256"

.PHONY: rawfs-test-q
rawfs-test-q: clean $(BUILD.RAWFS.disk)
	qemu-system-i386 -m 256 -serial stdio -fda $(BUILD.RAWFS.disk)

################################################################################

$(BUILD.RAWFS.disk): $(BUILD.RAWFS.stage1) \
					 $(BUILD.RAWFS.stage2) \
					 $(BUILD.KERNEL.stub)
	-mkdir $(BUILD)
	# Create a new disk image
	dd if=/dev/zero of=$@ bs=512 count=2880

	# Add the first stage (boot sector)
	dd if=$(BUILD.RAWFS.stage1) of=$@ bs=512 conv=notrunc

	# Add the test bootloader string
	patch -f $@ -a 512 -t str -l 32 -p 0 -d "RAWFS vboot test\r\n"

	# Add the second stage and information about it
	dd if=$(BUILD.RAWFS.stage2) of=$@ bs=512 seek=2 conv=notrunc
	patch -f $@ -a 544 -t dw -d 2
	patch -f $@ -a 546 -t dw -d $(shell $(TOOL.bsize) $(BUILD.RAWFS.stage2))

	# Add the kernel and information about it.
	dd if=$(BUILD.KERNEL.stub) of=$@ \
		bs=512 seek=$(shell \
			$(TOOL.bsize) $(BUILD.RAWFS.stage2) --offset=2 \
		) conv=notrunc
	patch -f $@ -a 548 -t dd -d $(shell $(TOOL.bsize) $(BUILD.RAWFS.stage2) \
		--offset=2 \
	)
	patch -f $@ -a 552 -t dd -d $(shell $(TOOL.bsize) $(BUILD.KERNEL.stub))

	# Specify the number of modules present.
	patch -f $@ -a 556 -t dd -d 1

	# Add Module 1: The ramdisk 
	dd if=$(BUILD.RAMDISK) of=$@ \
		bs=512 seek=$(shell \
			$(TOOL.bsize) $(BUILD.RAWFS.stage2) $(BUILD.KERNEL.stub) \
			--offset=2 \
		) conv=notrunc
	patch -f $@ -a 560 -t dd -d $(shell \
		$(TOOL.bsize) $(BUILD.RAWFS.stage2) $(BUILD.KERNEL.stub) --offset=2 \
	)
	patch -f $@ -a 564 -t dd -d $(shell $(TOOL.bsize) $(BUILD.RAMDISK))


$(BUILD.RAWFS.stage1):
	-mkdir $(BUILD)
	nasm -D__RAWFS__ -o $@ stage1/bios/raw.s

$(BUILD.RAWFS.stage2):
	-mkdir $(BUILD)
	nasm -D__RAWFS__ -o $@ stage2/bios/start.s

$(BUILD.KERNEL.stub):
	-mkdir -p $(BUILD)/kernel
	$(TOOL.CC) -ffreestanding -Wall -Wextra -nostdlib -nostdinc -fno-builtin \
	-fno-stack-protector -nostartfiles -nodefaultlibs -m32 \
	-finline-functions -std=c11 -O0 -fstrength-reduce \
	-fomit-frame-pointer -c -I./kernel -o build/kernel/kernel.o kernel/kernel.c
	$(TOOL.AS) -felf -o build/kernel/start.o kernel/kernel.s
	$(TOOL.LD) -Tkernel/kernel.ld -nostdlib -nostartfiles -o $@ \
		build/kernel/kernel.o \
		build/kernel/start.o
