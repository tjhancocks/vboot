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
	org		0x8000

; We need to jump over the configuration data for the bootloader. This 
; configuration is used to instruct the second stage on how to operate, and
; what to setup.
_entry:
	jmp short _start
_pref:
	.e820			db 	1	; Should an E820 memory map be searched for
	.acpi			db	1 	; Should ACPI information be determined
	.vesa 			db  0	; Should a VESA linear video mode be set
	.def_width		dw 	640 ; The default screen width if native not found
	.def_height		dw 	480 ; The default screen height if native not found

; The starting point for the second stage of the vboot bootloader.
_start:
	.enable_a20:
		in al, 0x92
		test al, 2
		jnz .a20_loaded
		or al, 2
		and al, 0xFE
		out 0x92, al
	.a20_loaded:
		call _go_unreal
		call _load_kernel
		; call _prepare_vesa
		; call _prepare_mmap
	.pmode_32:
		cli
		mov eax, cr0
		or al, 1
		mov cr0, eax
		mov eax, _pmode_gdt_info
		lgdt [eax]
		mov ax, 0x10
		mov ss, ax
		mov ds, ax
		mov es, ax
		mov fs, ax
		mov gs, ax
		jmp 0x08:_boot_kernel

; Protected Mode Data Structures
_pmode_gdt_info:
	dw _pmode_gdt_end - _pmode_gdt - 1
	dd _pmode_gdt

_pmode_gdt:
	dd 0, 0
	db 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x9a, 0xCF, 0x00	; Kernel Code
	db 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x92, 0xCF, 0x00	; Kernel Data
_pmode_gdt_end:

; Include all the required components for the second stage.
	%include "stage2/bios/raw.s"
	%include "stage2/bios/vesa.s"
	%include "stage2/bios/unreal.s"
	%include "stage2/bios/disk.s"
	%include "stage2/bios/elf.s"

; Boot Configuration - This is a structure that resides in memory and can be
; referenced later by the _third_ stage of the bootloader. The third stage will
; be responsible for loading the kernel and ramdisk, and will need to know about
; the configuration determined in this stage.
	BOOT_CONF		equ 0x7800
STRUC BootConf
	.vesa			resb 1
	.scr_width		resw 1
	.scr_height		resw 1
	.scr_depth		resb 1
ENDSTRUC

	bits 	32
_boot_kernel:
		mov esi, dword[$entry]
		mov eax, 0x2BADB002
		jmp esi