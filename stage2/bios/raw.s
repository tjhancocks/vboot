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
	.find_modules:
		mov si, RAWFS_ADDRESS
		mov ecx, dword[si + RawFS.module_count]
	.epilogue:
		mov sp, bp
		pop bp
		ret

%endif