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

STRUC BPB
	.jmpcode			resb 3
	.oem				resb 8
	.bps				resw 1
	.spc				resb 1
	.reservedSectors	resw 1
	.fatCount			resb 1
	.dirEntries			resw 1
	.totalSectors		resw 1
	.mediaDescriptor	resb 1
	.spf				resw 1
	.spt				resw 1
	.headCount			resw 1
	.hiddenSectors		resd 1
	.unknown			resd 1
	.drive				resb 1
	.dirty				resb 1
	.extendedSig		resb 1
	.volumeId			resd 1
	.volumeLabel		resb 11
	.fsType				resb 8
ENDSTRUC

; Convert a logical block address (LBA) into a cylinder-head-sector (CHS) 
; address.
_lbachs:
	.calculation:
		xor dx, dx
		div word[bp - 18]				; Divide by sectors per track
		inc dl							; ++
		mov byte[bp - 20], dl			; Store abs_sector
		xor dx, dx
		div word[bp - 26]				; Divide by head count
		mov byte[bp - 22], dl			; Store abs_head
		mov byte[bp - 24], al			; Store abs_track
	.epilogue:
		ret

; Read the specified number of sectors at a given location from the disk into 
; the provided memory location.
_read_sectors:
	.prologue:
		push bp
		mov bp, sp
	.stack_frame:
		push dword edi					; [bp - 4] 	void *dst
		push dword eax					; [bp - 8]  uint32_t sector
		push dword ecx					; [bp - 12] uint32_t count
		push dword 0					; [bp - 16] uint32_t idx
		push 0							; [bp - 18] uint16_t spt
		push 0							; [bp - 20] uint16_t abs_sector
		push 0							; [bp - 22] uint16_t abs_head
		push 0							; [bp - 24] uint16_t abs_track
		push 0							; [bp - 26] uint16_t head_count
		push 0							; [bp - 28] uint16_t drive
		push 0							; [bp - 30] uint16_t bps
	.initialise:
		mov di, 0x7c00					; We need to get values from the BPB
		movzx eax, word[di + BPB.spt]	; Fetch the sectors per track value...
		mov word[bp - 18], ax			; ... and store it locally.
		movzx eax, word[di + BPB.headCount]	; Fetch the head count value...
		mov word[bp - 26], ax			; ... and store it locally.
		movzx eax, word[di + BPB.drive]	; Fetch the drive number value...
		mov word[bp - 28], ax			; ... and store it locally.
		movzx eax, word[di + BPB.bps]	; Fetch the bytes per sector value...
		mov word[bp - 30], ax			; ... and store it locally.
	.calculate_sector:
		; We're going to calculate the next sector to read from, and the write
		; destination.
		mov eax, [bp - 8]				; Fetch the current sector
		mov ebx, [bp - 16]				; Fetch the current index
		add eax, ebx					; EAX += EBX
		call _lbachs 					; Convert the sector number to CHS
		xor ax, ax
		mov es, ax						; Restore ES to a zero segment.
		mov bx, 0x7e00					; Temporary storage for read sector.
	.drive_read:
		mov di, 5
	.next_attempt:
		mov ax, 0x0201					; Set the BIOS function for disk read
		mov ch, byte[bp - 24]			; CH = abs_track
		mov cl, byte[bp - 20]			; CL = abs_sector
		mov dh, byte[bp - 22]			; DH = abs_head
		mov dl, byte[bp - 28]			; DL = drive
		int 0x13						; Perform the drive read
		jnc .drive_read_success
		xor ax, ax						; Reset the drive
		int 0x13
		dec di							; Decrement the attempt counter
		cmp di, 0						; Have we reached zero?
		jnz .next_attempt
		int 0x18						; Retries exhausted. Report boot failure
	.drive_read_success:
		; We need to copy the sector to the appropriate location in memory. We
		; need to re-enable unreal mode on segment ES.
		mov eax, cr0
		or al, 1
		mov cr0, eax
		jmp .@@
  	.@@:
		mov bx, 0x8
		mov es, bx
		and al, 0xFE
		mov cr0, eax
		; We now need to work out exactly where the sector is going.
		mov edi, [bp - 4]				; EDI = dst
		mov eax, [bp - 16]				; EAX = idx
		movzx ecx, word[bp - 30]		; ECX = bps
		mul ecx							; EAX *= ECX
		add edi, eax					; EDI += EAX
		; and perform the copy...
		mov esi, 0x7e00
		mov cx, 0x200
		a32 rep movsb
	.next_sector:
		mov eax, [bp - 16]				; Fetch the current index
		inc eax							; Increment by one.
		mov [bp - 16], eax				; Update it for future use.
		mov ecx, [bp - 12]				; Fetch the current count
		cmp eax, ecx
		jge .read_finished				; We've finished reading the disk
		jmp .calculate_sector			; Read the next sector.
	.read_finished:
		; Clean up everything. We've finished reading the disk.
		mov sp, bp
		pop bp
		ret
