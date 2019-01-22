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

	bits          32

	global        start
	extern        kmain

	MOD_ALIGN     equ (1 << 0)
	MEM_INFO      equ (1 << 1)
	FLAGS         equ (MOD_ALIGN | MEM_INFO)
	MAGIC         equ 0x1BADB002
	CHKSUM        equ -(MAGIC + FLAGS)
	STK_SIZE      equ 0x4000

section .__mbHeader
align   4
	dd MAGIC
	dd FLAGS
	dd CHKSUM
	dd 0
	dd 0
	dd 0
	dd 0
	dd 0
	dd 0
	dd 640
	dd 480
	dd 32

section .text
align   4
start:
	cli
	mov 	esp, stack + STK_SIZE
	push 	ecx 					; Kernel Limit (upper address)
	push 	edx						; Kernel Base (lower address)
	push 	eax						; boot_magic number
	push 	ebx						; multiboot_info
	call 	kmain
	jmp 	$

section .bss
align   0x1000
stack:  resb STK_SIZE