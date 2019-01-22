; Copyright (c) 2019 Tom Hancocks
; 
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
; 
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

	bits	16

; The following variables are related to the kernel, and are more specifically
; determined when the kernel ELF file is parsed. These include the entry point
; for executing the kernel, its base location in memory and where it ends.
	$KERNEL_ENTRY			dd 0x00000000
	$KERNEL_BASE			dd 0xFFFFFFFF
	$KERNEL_SIZE			dd 0x00000000
	$KERNEL_LIMIT			dd 0x00000000

; These contain information about the modules loaded by vboot for the kernel.
; Information about modules needs to be provided via the multiboot information
; structure. For this we need to keep reference to where the list is located in
; memory, how many modules there are, as well as the range of memory that all of
; the modules occupy so that we do not overwrite or corrupt them.
	$MODULE_COUNT			db 0x00
	$MODULE_LIST			dd 0x00000000
	$MODULE_BASE			dd 0x00000000
	$MODULE_LIMIT			dd 0x00000000

; The memory map is a structure obtained about the layout of the systems 
; physical memory that is obtained from the BIOS. These variables contain 
; information about the physical memory of the computer that needs to be handed
; to the kernel via the multiboot information structure.
	$MMAP_COUNT				dd 0x00000000
	$MMAP_LENGTH			dd 0x00000000
	$MMAP_ADDRESS			dd 0x00000000
	$LOW_MEMORY				dd 0x00000000
	$UPPER_MEMORY			dd 0x00000000

; The following variables contain information about the graphics/text mode of
; the system.
	$LFB_ADDRESS			dd 0x00000000
	$VESA_MODE				db 0x00
	$VESA_WIDTH				dd 0x00000000
	$VESA_HEIGHT			dd 0x00000000
	$VESA_BPP				db 0x00
	$VESA_PITCH				db 0x00