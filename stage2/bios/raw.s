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

; This file contains the functions that are specific to handling a RAW 
; filesystem
%ifdef __RAWFS__

; Location of the RawFS meta-data. This meta-data contains information about
; where various "files" are located on disk.
	RAWFS_ADDRESS	equ 0x7a00

; Structural definition of the RawFS meta-data sector. 
STRUC RawFS
	.boot_message	resb 32
	.stage2_off		resw 1
	.stage2_len		resw 1
	.kernel_off		resd 1
	.kernel_len		resd 1
	.module_count 	resd 1
	.module_off		resd 1
	.module_len		resd 1
ENDSTRUC

; Load the kernel into memory. This assumes an ELF Kernel. The kernel will be
; loaded into memory from disk at the 16MiB mark, and then the ELF format parsed
; and final program code placed at the 1MiB mark (most likely. This may be
; influenced by the ELF file itself)
_load_kernel:
	.prologue:
		push bp
		mov bp, sp
	.find_kernel:
		mov si, RAWFS_ADDRESS
		mov eax, dword[si + RawFS.kernel_off]
		mov ecx, dword[si + RawFS.kernel_len]
		mov edi, 0x01000000						; Load at the 16MiB location
		call _read_sectors						; This is hard coded for now
	.parse_elf:
		mov edi, 0x01000000						; and should be adjusted to be
		call _load_elf							; dynamic...
	.epilogue:
		mov sp, bp
		pop bp
		ret

; Load any modules required by the kernel. This will be loaded into memory
; immediately after the end of the kernel, aligned to the next frame boundary.
_load_modules:
	.prologue:
		push bp
		mov bp, sp
	.stack_frame:
		push dword 0							; [bp - 4] module_addr
		push dword 0							; [bp - 8] module_struct
		push dword 0							; [bp - 12] module_list_size
		push dword 0							; [bp - 16] module_list_offset
		push dword 0							; [bp - 20] module_count
		push dword 0							; [bp - 24] module_index
	.prepare:
		xor eax, eax
		mov ds, ax
		mov es, ax
		mov esi, RAWFS_ADDRESS
		mov ecx, [es:esi + RawFS.module_count]	; Get the number of modules
		mov [bp - 20], ecx						; Save the number of modules
		mov eax, 16								; Module list entries are 16B
		mul ecx									; How much space for list?
		mov [bp - 12], eax						; Save the calulcation				
		add eax, 0x1000							; Add an entire page to it.
		and eax, 0xFFFFF000						; Align it to the page boundary
		mov ebx, dword[$KERNEL_LIMIT]			; Fetch the kernel end
		mov [$MODULE_LIST], ebx
		mov [bp - 16], ebx		
		add eax, ebx				 			; The first page after the list
		mov [bp - 4], eax						; Set the first module address
		mov [$MODULE_BASE], eax					; ...
	.handle_mod:
		unreal es
		unreal ds
		mov edi, [bp - 16]						; Get the list entry.
		mov eax, [bp - 4]						; Get the module address
		mov [ds:edi + Module.mod_start], eax	; Specify the module start addr
		mov ecx, eax							; Save for later
		mov esi, RAWFS_ADDRESS
		mov eax, [bp - 24]						; The module number/index
		mov ebx, 16
		mul ebx									; Multiply by list entry size
		add esi, eax							; Get the correct module info]
		mov eax, [ds:esi + RawFS.module_len]	; Multiply the sector count of
		mov ebx, 512							; the module by 512 bytes to get
		mul ebx									; the length of the module.
		add eax, ecx							; Add start to get the mod end.
		mov [ds:edi + Module.mod_end], eax		; Specify the module end addr
	.copy_mod:
		mov edi, [bp - 4]						; Get the copy destination
		mov eax, [ds:esi + RawFS.module_off]	; The module start sector
		mov ecx, [ds:esi + RawFS.module_len]	; The module sector count
		call _read_sectors						; Read the module to memory
	.next_mod:
		mov eax, dword[ds:edi + Module.mod_end]	; Where does the module end?
		mov [bp - 4], eax						; Load next module to there...
		mov eax, [bp - 16]						; Get the list entry and add
		add eax, 16								; 16 to it, ready for the next
		mov [bp - 16], eax						; module.
		inc dword[bp - 24]						; module_index++
		mov ecx, [bp - 20]						; Get the remaining module count
		dec ecx
		mov [bp - 20], ecx
		cmp ecx, 0
		jz .update_mb_info
		jmp .handle_mod
	.update_mb_info:
		mov edi, dword[_mb_info]
		mov esi, RAWFS_ADDRESS
		mov ecx, [es:esi + RawFS.module_count]; Get the number of modules
		mov [es:edi + MBInfo.mods_count], ecx ; Add it to the mb_info
		mov eax, [$MODULE_LIST]				  ; Fetch the location of the module
		mov [es:edi + MBInfo.mods_addr], eax  ; list and add it to mb_info
		xchg bx, bx
		mov eax, [es:edi + MBInfo.flags]
		or eax, MULTIBOOT_INFO_MODS			  ; State that there are modules
		mov [es:edi + MBInfo.flags], eax
	.epilogue:
		mov sp, bp
		pop bp
		ret

%endif