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
	org		0x7c00

; This is a basic bootsector for a "raw" disk without a file system. We have 
; limited information at our disposal, but enough to get the job done. This
; implementation depends on a BIOS, and may not work with UEFI systems.
; The fact this is a BIOS dependant implementation means that this is a stop
; gap implementation and should not be relied upon long term.

_entry:
	jmp short _start
	nop

; The BIOS parameter block. Some of this information is required for the BIOS to
; recognise and read the disk. The default information provided is for a floppy
; disk. This should be altered later by the patch tool.
_bpb:
	.oem				db "MSWIN4.1"
	.bps				dw 512
	.spc				db 1
	.reservedSectors	dw 0
	.fatCount			db 2
	.dirEntries			dw 224
	.totalSectors		dw 2880
	.mediaDescriptor	db 0xf8
	.spf				dw 9
	.spt				dw 18
	.headCount			dw 2
	.hiddenSectors		dd 0
	.unknown			dd 0
	.drive				db 0			; This value will get updated at runtime
	.dirty				db 1
	.extendedSig		db 0x29
	.volumeId			dd 77
	.volumeLabel		db "VeracyonOS "
	.fsType				db "RAWFS   "

; This is where we actually start booting. We need to first of all read the
; meta-data sector (sector 1) so that we can find the appropriate information
; to read everything that we require.
_start:
	; Make sure all interrupts are disabled and that our segments are correctly
	; configured.
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	; Get a basic stack setup. This must not be relied on long term as it may 
	; conflict with BIOS data.
	mov ss, ax
	mov sp, 0x7000

	; Make sure we have the boot drive number for later use.
	mov byte[_bpb.drive], dl

	; Fetch the first sector so that we have access to the required meta-data
	; that we need.
	mov ax, 1
	mov bx, 0x7a00
	mov cx, 1
	call _read_sectors

	; We should now have the meta data required. There is a confirmation boot 
	; message in the first 32-bytes. This is NUL terminated.
	mov si, 0x7a00
	call _puts

	; We now need to fetch information about the sectors containing the second
	; stage of the bootloader.
	mov ax, word[0x7a00 + 0x20]
	mov cx, word[0x7a00 + 0x22]
	mov bx, 0x8000
	call _read_sectors

	; We should be able to load the second stage of the bootloader now.
	jmp 0x8000

; Convert a logical block address (LBA) into a cylinder-head-sector (CHS) 
; address.
_lbachs:
	xor dx, dx
	div word[_bpb.spt]
	inc dl
	mov byte[_read_sectors.abs_sector], dl
	xor dx, dx
	div word[_bpb.headCount]
	mov byte[_read_sectors.abs_head], dl
	mov byte[_read_sectors.abs_track], al
	ret

; Read the specified number of sectors at a given location from the disk into 
; the provided memory location.
_read_sectors:
  .L0:
  	mov di, 5               ; Attempts
  .L1:
  	pusha
  	call _lbachs
  	mov ah, 0x02
  	mov al, 0x01
  	mov ch, [.abs_track]
  	mov cl, [.abs_sector]
  	mov dh, [.abs_head]
  	mov dl, [_bpb.drive]
  	int 0x13
  	jnc .successful_read
  	dec di
  	popa
  	jnz .L1
  	int 0x18
  .successful_read:
  	popa
  	add bx, [_bpb.bps]
  	inc ax
  	loop .L0
  	ret
  .abs_track:
  	db 0
  .abs_sector:
  	db 0
  .abs_head:
  	db 0

; Print a string to the screen.
_puts:
  	mov ah, 0x0e
  .next:
  	lodsb
  	or al, al
  	jz .eos
  	int 0x10
  	jmp .next
  .eos:
	ret

; Ensure the bootsector is not too large, and has the required signature.
    times 0x1FE-($-$$) db 0
    dw 0xAA55