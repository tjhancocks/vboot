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

	bits 	16

$entry					dd 0

STRUC ELFIdent
	.e_magic			resd 1
	.e_class 			resb 1
	.e_data				resb 1
	.e_version			resb 1
	.e_os_abi			resb 1
	.e_abi_version		resb 1
	.e_pad				resb 7
ENDSTRUC

STRUC ELFHdr
	.e_ident			resb 16
	.e_type				resw 1
	.e_machine			resw 1
	.e_version			resd 1
	.e_entry			resd 1
	.e_phoff			resd 1
	.e_shoff			resd 1
	.e_flags			resd 1
	.e_ehsize			resw 1
	.e_phentsize		resw 1
	.e_phnum			resw 1
	.e_shentsize		resw 1
	.e_shnum			resw 1
	.e_shstrndx			resw 1
ENDSTRUC

STRUC ELFPhdr
	.p_type				resd 1
	.p_offset			resd 1
	.p_vaddr			resd 1
	.p_paddr 			resd 1
	.p_filesz			resd 1
	.p_memsz			resd 1
	.p_flags			resd 1
	.p_align 			resd 1
ENDSTRUC

STRUC ELFShdr
	.sh_name			resd 1
	.sh_type			resd 1
	.sh_flags			resd 1
	.sh_addr 			resd 1
	.sh_offset			resd 1
	.sh_size			resd 1
	.sh_link			resd 1
	.sh_info			resd 1
	.sh_addralign		resd 1
	.sh_entsize			resd 1
ENDSTRUC

; This function will parse, verify and load the specified ELF program into 
; memory. It will not lead to the ELF program being launched directly. As part
; of this process, the multiboot header will be examined and the appropriate
; actions will be taken to ensure an environment that the kernel expects.
_load_elf:
	.prologue:
		push bp
		mov bp, sp
	.stack_frame:
		push dword edi					; [bp - 4] elf_data
	.elf:
		call _check_elf
		call _parse_elf_phdr
	.entry_point:
		xchg bx, bx
		mov esi, [bp - 4]
		mov eax, [es:esi + ELFHdr.e_entry]
		mov dword[$entry], eax
	.epilogue:
		mov sp, bp
		pop bp
		ret

; Check that the ELF file specified is actually a valid ELF file.
_check_elf:
	.fetch_header:
		unreal ds
		mov edi, [bp - 4]				; EDI = &elf_data
		add edi, ELFHdr.e_ident
	.check_magic:
		mov eax, [ds:edi + ELFIdent.e_magic]
		cmp eax, 0x464C457F				; Is the magic number correct?
		je .check_class
		int 0x18
	.check_class:
		mov al, [ds:edi + ELFIdent.e_class]
		cmp al, 1						; Is this the 32-bit class?
		je .check_data
		int 0x18
	.check_data:
		mov al, [ds:edi + ELFIdent.e_data]
		cmp al, 1						; Is the little endian data format?
		je .check_e_version
		int 0x18
	.check_e_version:
		mov al, [ds:edi + ELFIdent.e_version]
		cmp al, 1						; Check that the version is correct.
		je .check_arch
		int 0x18 
	.check_arch:
		mov edi, [bp - 4]				; EDI = &elf_data
		mov ax, [ds:edi + ELFHdr.e_machine]
		cmp ax, 3						; Is the architecture i386?
		je .check_type
		int 0x18
	.check_type:
		mov ax, [ds:edi + ELFHdr.e_type]
		cmp ax, 2						; Is the ELF executable?
		je .elf_fine
		int 0x18
	.elf_fine:
		ret

_parse_elf_phdr:
	.stack_frame:
		push dword 0					; [bp - 10] phdr_offset
		push 0							; [bp - 12] phdr_count
		push 0							; [bp - 14] phdr_size
	.locate_program_headers:
		unreal ds
		mov edi, [bp - 4]				; EDI = &elf_data
		mov eax, [ds:edi + ELFHdr.e_phoff]
		add eax, edi					; EAX += EDI
		mov [bp - 10], eax				; phdr_offset = EAX
		movzx eax, word[ds:edi + ELFHdr.e_phnum]
		mov [bp - 12], ax				; phdr_count = EAX
		movzx eax, word[ds:edi + ELFHdr.e_phentsize]
		mov [bp - 14], ax				; phdr_size = EAX
	.handle_entry:
		mov edi, [bp - 10]				; EDI = phdr_offset
		mov eax, [ds:edi + ELFPhdr.p_type]
		cmp eax, 0x0					; Skip NULL sections...
		je .next_entry
		cmp eax, 0x1					; Load section?
		je .handle_load_section
		int 0x18						; Section is unsupported
	.handle_load_section:
		call _load_elf_section
	.next_entry:
		mov eax, [bp - 10]				; EAX = phdr_offset
		movzx ebx, word[bp - 14]
		add eax, ebx					; EAX += phdr_size
		mov [bp - 10], eax				; phdr_offset = EAX
		mov cx, [bp - 12]				; ECX = phdr_count
		dec cx							; --ECX
		mov [bp - 12], cx				; phdr_count = ECX
		cmp cx, 0						; if ECX == 0
		jz .epilogue
		jmp .handle_entry
	.epilogue:
		add esp, 8
		ret

_load_elf_section:
	.prepare:
		unreal es
		unreal ds
		mov esi, [bp - 10]				; ESI = phdr_offset
		mov edi, [es:esi + ELFPhdr.p_vaddr]
		mov ecx, [es:esi + ELFPhdr.p_filesz]
		mov esi, [es:esi + ELFPhdr.p_offset]
		add esi, dword[bp - 4]			; ESI += elf_data
	.copy:
		a32 rep movsb
	.epilogue:
		ret