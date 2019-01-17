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

STRUC MBHeader
	.magic					resd 1
	.flags					resd 1
	.checksum				resd 1
	.header_addr			resd 1
	.load_addr				resd 1
	.load_end_addr			resd 1
	.bss_end_addr			resd 1
	.entry_addr 			resd 1
	.mode_type				resd 1
	.width					resd 1
	.height					resd 1
	.depth 					resd 1
ENDSTRUC

STRUC MBInfo
	.flags					resd 1
	.mem_lower				resd 1
	.mem_upper 				resd 1
	.boot_device			resd 1
	.cmdline				resd 1
	.mods_count				resd 1
	.mods_addr 				resd 1
	.syms 					resd 3
	.mmap_length			resd 1
	.mmap_addr				resd 1
	.drives_length			resd 1
	.drives_addr 			resd 1
	.config_table			resd 1
	.boot_loader_name		resd 1
	.apm_table				resd 1
	.vbe_control_info		resd 1
	.vbe_mode_info			resd 1
	.vbe_mode				resd 1
	.vbe_interface_seg		resd 1
	.vbe_interface_off		resd 1
	.vbe_interface_len		resd 1
	.framebuffer_addr		resd 1
	.framebuffer_pitch		resd 1
	.framebuffer_width		resd 1
	.framebuffer_height		resd 1
	.framebuffer_bpp		resb 1
	.framebuffer_type		resb 1
	.color_info				resb 5
ENDSTRUC

STRUC Module
	.mod_start				resd 1
	.mod_end				resd 1
	.string					resd 1
	.reserved				resd 1
ENDSTRUC

STRUC MMap
	.size					resd 1
	.base_addr				resq 1
	.length					resq 1
	.type					resd 1
ENDSTRUC
