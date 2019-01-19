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

; Query the BIOS for information about the memory layout of the system. With
; this there are two types of memory information gathered. One is a fall back to
; the other.
;
;	1. Upper and Lower memory - this is a fall back option. It does not give 
;	   much in the way of reliable information.
;	2. Memory Map - this is the preferred option for the kernel to make use of.
;	   It provides information about how physical memory is laid out, what is
; 	   usable and what is not usable.
;
; The memory map needs to be translated to be compliant with the multiboot 
; specification.
_detect_memory_bios:
	.detect_low_memory:
		xor ax, ax							; Make sure we reset DS back to
		mov ds, ax							; Real Mode, or we'll crash!
		clc
		int 0x12							; Detect lower memory.
		unreal es
		mov edi, dword[_mb_info]			; Write it into the multiboot info
		mov dword[es:edi + MBInfo.mem_lower], eax
	.read_memory_map:
		call _read_memory_map 				; Attempt to read the memory map.
		jnc .calculate_upper_memory			; Calculate upper memory if success
		int 0x18							; Indicate a boot failure.
	.calculate_upper_memory:
		mov edi, dword[_mb_info]
		mov eax, dword[es:edi + MBInfo.mmap_length]
		mov esi, dword[es:edi + MBInfo.mmap_addr]
		mov edx, dword[es:edi + MBInfo.mem_upper]
		mov ecx, 24
		div ecx
		mov ecx, eax
	.next_entry:
		mov eax, dword[es:esi + 8]			; Fetch the lower length
		mov ebx, dword[es:esi + 16]			; Fetch the type
		cmp ebx, 1							; Is the block free for use?
		jne .skip_entry
		shr eax, 10							; Get the number of KiB
		add edx, eax						; EDX += EAX
	.skip_entry:
		add esi, 24							; Move to the next entry
		loop .next_entry
	.finish_upper_memory:
		xor ax, ax
		mov ds, ax
		mov edi, dword[_mb_info]
		mov eax, dword[es:edi + MBInfo.mem_lower]
		xchg eax, edx
		sub eax, edx
		mov dword[es:edi + MBInfo.mem_upper], edx
	.update_flags:
		mov eax, dword[es:edi + MBInfo.flags]
		or eax, (MULTIBOOT_INFO_MEMORY | MULTIBOOT_INFO_MEM_MAP)
		mov dword[es:edi + MBInfo.flags], eax
	.epilogue:
		ret

; This is an involved routine, and makes use of most of the general purpose
; registers. It reads the memory map from the BIOS, using INT 0x15/EAX=E820.
_read_memory_map:
	.prepare:
		push bp
		mov bp, sp
		push bp
		xor ax, ax
		mov ds, ax							; Ensure real mode DS segment
		mov ax, 0x2000						; Memory map will be located at
		mov es, ax							; 0x20000 onwards.
		xor edi, edi
	.do_e820:
		xor ebx, ebx
		xor ebp, ebp
		mov edx, 0x534d4150
		mov eax, 0xe820
		mov [es:di + 20], dword 1
		mov ecx, 24
		int 0x15
		jc .failed
		mov edx, 0x534d4150
		cmp eax, edx
		jne .failed
		test ebx, ebx
		je .failed
		jmp .jmpin
	.e820lp:
		mov eax, 0xe820
		mov [es:di + 20], dword 1
		mov ecx, 24
		int 0x15
		jc .e820f
		mov edx, 0x534d4150
	.jmpin:
		jcxz .skipent
		cmp cl, 20
		jbe .notext
		test byte[es:di + 20], 1
		je .skipent
	.notext:
		mov ecx, [es:di + 8]
		or ecx, [es:di + 12]
		jz .skipent
		inc bp
		add di, 24
	.skipent:
		test ebx, ebx
		jne .e820lp
	.e820f:
		unreal es
		mov esi, dword[_mb_info]
		mov eax, ebp
		mov ecx, 24
		mul ecx
		mov dword[es:esi + MBInfo.mmap_length], eax
		mov dword[es:esi + MBInfo.mmap_addr], 0x20000
		clc
		jmp .epilogue
	.failed:
		xchg bx, bx
		stc
	.epilogue:
		pop bp
		mov sp, bp
		pop bp
		ret