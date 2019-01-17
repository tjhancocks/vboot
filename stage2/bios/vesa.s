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

	VESA_INFO			equ 0xF000
	VBE_MODE			equ 0xF200
	EDID_INFO			equ 0xF400

; The following defines the layout of the VESA VBE Info structure.
STRUC VBEInfo
	.signature 			resb 4
	.version 			resw 1
	.oem				resd 1
	.capabilities		resd 1
	.video_modes_off	resw 1
	.video_modes_seg	resw 1
	.video_memory		resw 1
	.software_revision	resw 1
	.vendor				resd 1
	.product_name		resd 1
	.product_revision	resd 1
	.reserved			resb 222
	.oem_data			resb 256
ENDSTRUC

; The following defines the layout of the EDID structure. EDID is used by the
; hardware to instruct the software of its preferred/native resolution.
STRUC EDID
	.padding 			resb 8
	.manufacturer_id	resw 1
	.edid_code			resw 1
	.serial_code		resd 1
	.week_number		resb 1
	.manufacturer_year	resb 1
	.edid_version		resb 1
	.edid_revision		resb 1
	.video_input		resb 1
	.width_cm			resb 1
	.height_cm			resb 1
	.gamma_factor		resb 1
	.dpms_flags			resb 1
	.chroma				resb 10
	.timings1			resb 1
	.timings2			resb 1
	.reserved_timing	resb 1
	.standard_timings	resw 8
	.timing_desc1		resb 18
	.timing_desc2		resb 18
	.timing_desc3		resb 18
	.timing_desc4		resb 18
	.reserved			resb 1
	.checksum			resb 1
ENDSTRUC

; The following defines the layout of the VBE Mode Info structure. This
; structure describes the configuration and how to use the mode.
STRUC VBEMode
	.attributes			resb 2
	.window_a			resb 1
	.window_b 			resb 1
	.granularity		resb 2
	.window_size		resb 2
	.segment_a			resb 2
	.segment_b			resb 2
	.win_func_ptr		resb 4
	.pitch				resb 2
	.width				resb 2
	.height				resb 2
	.w_char				resb 1
	.h_char				resb 1
	.planes				resb 1
	.bpp				resb 1
	.banks				resb 1
	.memory_model		resb 1
	.bank_size			resb 1
	.image_pages		resb 1
	.reserved0			resb 1
	.red_mask			resb 1
	.red_position		resb 1
	.green_mask			resb 1
	.green_position		resb 1
	.blue_mask			resb 1
	.blue_position		resb 1
	.reserved_mask		resb 1
	.reserved_position	resb 1
	.direct_color_attr	resb 1
	.frame_buffer		resb 4
	.off_screen_mem_off	resb 4
	.off_screen_mem_sz	resb 2
	.reserved1			resb 206
ENDSTRUC

_prepare_vesa:
  .prologue:
  	push bp
  	mov bp, sp
  	push 0							; [bp-2] vbe mode number
  	push 0							; [bp-4] vbe mode offset
  .check_vga_text_mode:
	cmp byte[_pref.vesa], 0		; Are we wanting VESA?
	jne .vesa
  .no_vesa:
  	jmp .epilogue
  .vesa:
  	push es
  	mov di, VESA_INFO
  	mov dword[di + VBEInfo.signature], "VBE2"
  	mov ax, 0x4F00					; BIOS function to get VESA VBE info
  	int 0x10
  	pop es
  	cmp ax, 0x004f					; Success?
  	je .L1
  	jmp .vesa_error
  .L1:
  	mov di, VESA_INFO
  	mov eax, dword[di + VBEInfo.signature]
  	cmp eax, "VESA"					; Have we go back the correct thing?
  	je .L2
  	jmp .vesa_error
  .L2:
  	movzx eax, word[di + VBEInfo.version]
  	cmp ax, 0x0200					; Is the VESA version too old?
  	jge .read_edid
  	jmp .vesa_error
  .read_edid:
  	push es
  	mov eax, 0x4f15					; BIOS function to get EDID info
  	mov ebx, 0x1
  	xor ecx, ecx
  	xor edx, edx
  	mov edi, EDID_INFO
  	int 0x10
  	pop es
  	cmp ax, 0x004f					; Success?
  	jne .L3
  	nop
  	jmp .find_preferred_vbe_mode
  .L3:
  	jmp .use_default_vbe_mode
  .find_preferred_vbe_mode:
  	mov di, EDID_INFO
  	mov si, BOOT_CONF
  	movzx eax, byte[di + EDID.timing_desc1]
  	or al, al
  	jz .L3							; Bad data. Use default mode instead
  	movzx eax, byte[di + EDID.timing_desc1 + 2] ; Low byte of Width
  	mov word[si + BootConf.scr_width], ax
  	movzx eax, byte[di + EDID.timing_desc1 + 4]
  	and eax, 0xF0
  	shl eax, 4
  	or word[si + BootConf.scr_width], ax
  	movzx eax, byte[di + EDID.timing_desc1 + 5] ; Low byte of Height
  	mov word[si + BootConf.scr_height], ax
  	movzx eax, byte[di + EDID.timing_desc1 + 7]
  	and eax, 0xF0
  	shl eax, 4
  	or word[si + BootConf.scr_height], ax
  .validate_mode:
  	mov si, BOOT_CONF
  	movzx eax, word[si + BootConf.scr_width]
  	or ax, ax
  	jz .use_default_vbe_mode
  	movzx eax, word[si + BootConf.scr_height]
  	or ax, ax
  	jz .use_default_vbe_mode
  	nop
  	jmp .set_vbe_mode
  .use_default_vbe_mode:
  	mov si, BOOT_CONF
  	movzx eax, word[_pref.def_width]
  	movzx ebx, word[_pref.def_height]
  	mov word[si + BootConf.scr_width], ax
  	mov word[si + BootConf.scr_height], bx
  .set_vbe_mode:
  	mov word[si + BootConf.scr_depth], 32
  	mov di, VESA_INFO
  	movzx esi, word[di + VBEInfo.video_modes_off]
  	mov [bp - 4], si				; Keep the VBE offset in local memory
  .find_vbe_mode:
  	push fs
  	mov di, VESA_INFO
  	movzx eax, word[di + VBEInfo.video_modes_seg]
  	mov fs, ax
  	movzx esi, word[bp - 4]			; Fetch the offset
  	movzx edx, word[fs:si]
  	add si, 2
  	mov word[bp - 4], si			; Update the offset
  	mov word[bp - 2], dx			; Update the current mode
  	pop fs
  	movzx eax, word[bp - 2]			; Fetch the current mode
  	cmp ax, 0xffff					; Is this the end of the list?
  	je .vbe_mode_not_found
  	nop
  	jmp .get_vbe_mode_info
  .vbe_mode_not_found:
  	jmp .vesa_error
  .get_vbe_mode_info:
  	push es
  	mov ax, 0x4f01					; BIOS function to get VBE mode info
  	movzx ecx, word[bp - 2]			; Fetch the current mode
  	mov di, VBE_MODE
  	int 0x10
  	pop es
  	cmp ax, 0x004f					; Success?
  	jne .L4
  	nop
  	jmp .check_vbe_mode
  .L4:
  	jmp .vesa_error
  .check_vbe_mode:
  	mov di, VBE_MODE
  	mov si, BOOT_CONF
  	movzx eax, word[si + BootConf.scr_width]
  	movzx ebx, word[di + VBEMode.width]
  	cmp ax, bx
  	jne .next_vbe_mode				; Incorrect width
  	movzx eax, word[si + BootConf.scr_height]
  	movzx ebx, word[di + VBEMode.height]
  	cmp ax, bx
  	jne .next_vbe_mode				; Incorrect height
  	movzx eax, byte[si + BootConf.scr_depth]
  	movzx ebx, byte[di + VBEMode.bpp]
  	cmp ax, bx
  	jne .next_vbe_mode				; Incorrect depth
  	movzx eax, word[di + VBEMode.attributes]
  	cmp ax, 0x0081
  	jz .next_vbe_mode				; No linear frame buffer
  	nop
  	jmp .found_vbe_mode
  .next_vbe_mode:
  	jmp .find_vbe_mode
  .found_vbe_mode:
  	push es
  	mov ax, 0x4f02					; BIOS function to set the VESA mode
  	movzx ebx, word[bp - 2]			; Fetch the current VBE mode
  	or ebx, 0x4000
  	xor cx, cx
  	xor dx, dx
  	xor di, di
  	int 0x10
  	pop es
  	cmp ax, 0x004f
  	jne .L5
  	nop
  	jmp .save_vbe_info
  .L5:
  	jmp .vesa_error
  .save_vbe_info:
  	jmp .epilogue
  .vesa_error:
  	nop
  	mov si, BOOT_CONF
  	mov byte[si + BootConf.vesa], 0		; Disable VESA in the config.
  	jmp .epilogue
  .epilogue:
  	mov sp, bp
  	pop bp
  	ret
