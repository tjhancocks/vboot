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

%macro unreal 1
	push eax
	mov eax, cr0
	or al, 1
	mov cr0, eax
	jmp $+2
	mov bx, 0x8
	mov %1, bx
	and al, 0xFE
	mov cr0, eax
	and al, 0xFE
	mov cr0, eax
	pop eax
%endmacro

_go_unreal:
  .setup_unreal_mode:
	cli
	lgdt [_unreal_gdt_info]
	sti
	ret

_unreal_gdt_info:
	dw _unreal_gdt_end - _unreal_gdt - 1
	dd _unreal_gdt

_unreal_gdt:
	dd 0, 0
	db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
_unreal_gdt_end: