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

	RAWFS_ADDRESS	equ 0x7a00

STRUC RawFS
	.boot_message	resb 32
	.stage2_off		resw 1
	.stage2_len		resw 1
	.kernel_off		resd 1
	.kernel_len		resd 1
	.ramdisk_off	resd 1
	.ramdisk_len	resd 1
ENDSTRUC

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

%endif