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
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; This file is intended to match the multiboot.h file as closely as possible
; with appropriate translations in to intel syntax assembly made. As such I have
; included the original copyright statement of the multiboot.h file.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; multiboot.h - Multiboot header file.
; Copyright (C) 1999,2003,2007,2008,2009  Free Software Foundation, Inc.
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to
; deal in the Software without restriction, including without limitation the
; rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
; sell copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL ANY
; DEVELOPER OR DISTRIBUTOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
; IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


; How many bytes from the start of the file we search for the header. 
%define MULTIBOOT_SEARCH                        8192

; The magic field should contain this. 
%define MULTIBOOT_HEADER_MAGIC                  0x1BADB002

; This should be in %eax. 
%define MULTIBOOT_BOOTLOADER_MAGIC              0x2BADB002

; The bits in the required part of flags field we don't support. 
%define MULTIBOOT_UNSUPPORTED                   0x0000fffc

; Alignment of multiboot modules. 
%define MULTIBOOT_MOD_ALIGN                     0x00001000

; Alignment of the multiboot info structure. 
%define MULTIBOOT_INFO_ALIGN                    0x00000004

; Flags set in the 'flags' member of the multiboot header. 

; Align all boot modules on i386 page (4KB) boundaries. 
%define MULTIBOOT_PAGE_ALIGN                    0x00000001

; Must pass memory information to OS. 
%define MULTIBOOT_MEMORY_INFO                   0x00000002

; Must pass video information to OS. 
%define MULTIBOOT_VIDEO_MODE                    0x00000004

; This flag indicates the use of the address fields in the header. 
%define MULTIBOOT_AOUT_KLUDGE                   0x00010000

; Flags to be set in the 'flags' member of the multiboot info structure. 

; is there basic lower/upper memory information? 
%define MULTIBOOT_INFO_MEMORY                   0x00000001
; is there a boot device set? 
%define MULTIBOOT_INFO_BOOTDEV                  0x00000002
; is the command-line defined? 
%define MULTIBOOT_INFO_CMDLINE                  0x00000004
; are there modules to do something with? 
%define MULTIBOOT_INFO_MODS                     0x00000008

; These next two are mutually exclusive 

; is there a symbol table loaded? 
%define MULTIBOOT_INFO_AOUT_SYMS                0x00000010
; is there an ELF section header table? 
%define MULTIBOOT_INFO_ELF_SHDR                 0x00000020

; is there a full memory map? 
%define MULTIBOOT_INFO_MEM_MAP                  0x00000040

; Is there drive info? 
%define MULTIBOOT_INFO_DRIVE_INFO               0x00000080

; Is there a config table? 
%define MULTIBOOT_INFO_CONFIG_TABLE             0x00000100

; Is there a boot loader name? 
%define MULTIBOOT_INFO_BOOT_LOADER_NAME         0x00000200

; Is there a APM table? 
%define MULTIBOOT_INFO_APM_TABLE                0x00000400

; Is there video information? 
%define MULTIBOOT_INFO_VIDEO_INFO               0x00000800

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
	.syms 					resd 4
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
	.color_info				resb 6
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

_prepare_mb_info:
	.prologue:
		push bp
		mov bp, sp
	.clear:	
		xor eax, eax
		mov es, ax
		mov ds, ax
		mov ecx, 29
		mov edi, dword[_mb_info]
		a32 rep stosd
	.boot_loader_name:
		mov edi, dword[_mb_info]
		mov eax, _vboot_name
		mov dword[es:edi + MBInfo.boot_loader_name], eax
	.lower_upper_memory:
		call _detect_memory_bios
	.epilogue:
		mov sp, bp
		pop bp
		ret