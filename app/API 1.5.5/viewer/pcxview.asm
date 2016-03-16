	BITS 16
	%INCLUDE "pixapi.inc"
	ORG 32768

main_start:
	mov bx, picture_string
	mov ax, bx
	mov cx, 36864
	call os_load_file

	mov ah, 0			; Switch to graphics mode
	mov al, 13h
	int 10h

	mov ax, 0A000h			; ES = video memory
	mov es, ax

	mov si, 36864+80h
					; (First 80h bytes is header)

	mov di, 0			; Start our loop at top of video

decode:
	mov cx, 1
	lodsb
	cmp al, 192			; Single pixel or string?
	jb single
	and al, 63			; String, so 'mod 64' it
	mov cl, al			; Result in CL for following 'rep'
	lodsb				; Get byte to put on screen
single:
	rep stosb			; And show it (or all of them)
	cmp di, 64001
	jb decode


	mov dx, 3c8h			; Palette index register
	mov al, 0			; Start at colour 0
	out dx, al			; Tell VGA controller that...
	inc dx				; ...3c9h = palette data register

	mov cx, 768			; 256 colours, 3 bytes each
setpal:
	lodsb				; Grab the next byte.
	shr al, 2			; Palettes divided by 4, so undo
	out dx, al			; Send to VGA controller
	loop setpal


	call os_wait_for_key

	mov ax, 3			; Back to text mode
	mov bx, 0
	int 10h
	mov ax, 1003h			; No blinking text!
	int 10h

	mov ax, 2000h			; Reset ES back to original value
	mov es, ax
	jmp close

close:
	call os_clear_screen
	ret


draw_background:
	mov ax, title_msg		; Set up screen
	mov bx, footer_msg
	mov cx, BLACK_ON_WHITE
	call os_draw_background
	ret

picture_string	db 'boot.pcx', 0
title_msg	db 'PixOS Text/Picture Viewer', 0
footer_msg	db 'Press Esc to exit', 0