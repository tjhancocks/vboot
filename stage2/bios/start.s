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

; Read-only constants used in the second stage of the vboot bootloader.
_vboot_name:		db "vboot bootloader v0.1", 0x00
_mb_info:			dd 0x10000

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
		call _prepare_mb_info
		call _load_modules
	.pmode_32:
		cli
		xor ax, ax							; Make sure we're back to a normal
		mov ds, ax							; real mode segment or we'll crash
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
	%include "stage2/bios/variables.s"
	%include "stage2/bios/multiboot.s"
	%include "stage2/bios/raw.s"
	%include "stage2/bios/vesa.s"
	%include "stage2/bios/unreal.s"
	%include "stage2/bios/disk.s"
	%include "stage2/bios/elf.s"
	%include "stage2/bios/memory.s"

; We need a small 32-bit stub in which to jump too when setting the CS segment
; register. This stub simply needs to perform a jump into the kernel.
	bits 	32
_boot_kernel:
		mov esi, dword[$KERNEL_ENTRY]
		mov eax, MULTIBOOT_BOOTLOADER_MAGIC
		mov ebx, dword[_mb_info]
		jmp esi