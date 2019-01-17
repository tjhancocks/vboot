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
TOOL.bsize = $(ROOT)/tool/bsize/bsize.sh

# This is a bit of a hack. We should have a small test kernel in the vboot
# repo that can be used used for validating the multiboot information generated
# by vboot.
vkernel = $(ROOT)/../vkernel/build/kernel

################################################################################

.PHONY: all
all: $(BUILD.RAWFS.disk)

.PHONY: clean
clean:
	-rm -rf $(BUILD)

.PHONY: rawfs-test
rawfs-test: clean $(BUILD.RAWFS.disk)
	bochs -q "boot:a" "floppya: 1_44=$(BUILD.RAWFS.disk), status=inserted" \
		"magic_break: enabled=1"

################################################################################

$(BUILD.RAWFS.disk): $(BUILD.RAWFS.stage1) $(BUILD.RAWFS.stage2)
	-mkdir $(BUILD)
	dd if=/dev/zero of=$@ \
		bs=512 count=2880
	dd if=$(BUILD.RAWFS.stage1) of=$@ \
		bs=512 conv=notrunc
	dd if=$(BUILD.RAWFS.stage2) of=$@ \
		bs=512 seek=2 conv=notrunc
	dd if=$(vkernel) of=$@ \
		bs=512 seek=$(shell \
			$(TOOL.bsize) $(BUILD.RAWFS.stage2) --offset=2 \
		) conv=notrunc
	patch -f $@ -a 512 -t str -l 32 -p 0 -d "RAWFS vboot test\r\n"
	patch -f $@ -a 544 -t dw -d 2 # Start of stage 2
	patch -f $@ -a 546 -t dw -d $(shell \
		$(TOOL.bsize) $(BUILD.RAWFS.stage2) \
	)
	patch -f $@ -a 548 -t dd -d $(shell \
		$(TOOL.bsize) $(BUILD.RAWFS.stage2) --offset=2 \
	)
	patch -f $@ -a 552 -t dd -d $(shell \
		$(TOOL.bsize) $(BUILD.RAWFS.stage2) $(vkernel) --offset=2 \
	)

$(BUILD.RAWFS.stage1):
	-mkdir $(BUILD)
	nasm -D__RAWFS__ -o $@ stage1/bios/raw.s

$(BUILD.RAWFS.stage2):
	-mkdir $(BUILD)
	nasm -D__RAWFS__ -o $@ stage2/bios/start.s
