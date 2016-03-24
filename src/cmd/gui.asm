;==================================GUI===============================;
os_file_selector:
	pusha

	mov word [.filename], 0		; Terminate string in case user leaves without choosing

	mov ax, .buffer			; Get comma-separated list of filenames
	call os_get_file_list

	mov ax, .buffer			; Show those filenames in a list dialog box
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog

	jc .esc_pressed

	dec ax				; Result from os_list_box starts from 1, but
					; for our file list offset we want to start from 0

	mov cx, ax
	mov bx, 0

	mov si, .buffer			; Get our filename from the list
.loop1:
	cmp bx, cx
	je .got_our_filename
	lodsb
	cmp al, ','
	je .comma_found
	jmp .loop1

.comma_found:
	inc bx
	jmp .loop1


.got_our_filename:			; Now copy the filename string
	mov di, .filename
.loop2:
	lodsb
	cmp al, ','
	je .finished_copying
	cmp al, 0
	je .finished_copying
	stosb
	jmp .loop2

.finished_copying:
	mov byte [di], 0		; Zero terminate the filename string

	popa

	mov ax, .filename

	clc
	ret


.esc_pressed:				; Set carry flag if Escape was pressed
	popa
	stc
	ret


	.buffer		times 1024 db 0

	.help_msg1	db 'Please select a TXT, INC or PCX file', 0
	.help_msg2	db '', 0

	.filename	times 13 db 0

os_list_dialog:
	pusha

	push ax				; Store string list for now

	push cx				; And help strings
	push bx

	call os_hide_cursor


	mov cl, 0			; Count the number of entries in the list
	mov si, ax
.count_loop:
	lodsb
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl

	;==========CLOSE==========;
	mov bl, 01111111b		; White on grey
	mov dl, 20			; Start X position
	mov dh, 2			; Start Y position
	mov si, 1			; Width
	mov di, 3			; Finish Y position
	call os_draw_block		; Draw option selector window
	mov si, buttons
	call print_string

	;==============End=Window=test==========;

	mov bl, 01111111b		; White on grey
	mov dl, 20			; Start X position
	mov dh, 3			; Start Y position
	mov si, 40			; Width
	mov di, 23			; Finish Y position
	call os_draw_block		; Draw option selector window
	mov si, exit
	call print_string

	mov dl, 21			; Show first line of help text...
	mov dh, 3
	call os_move_cursor

	pop si				; Get back first string
	call print_string

	inc dh				; ...and the second
	call os_move_cursor

	pop si
	call print_string


	pop si				; SI = location of option list string (pushed earlier)
	mov word [.list_string], si


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov dl, 25			; Set up starting position for selector
	mov dh, 7

	call os_move_cursor

.more_select:
	pusha
	mov bl, 11110000b		; Black on white for option list box
	mov dl, 21
	mov dh, 6
	mov si, 38
	mov di, 22
	call os_draw_block
	popa

	call .draw_black_bar

	mov word si, [.list_string]
	call .draw_list

.another_key:
	call os_wait_for_key		; Move / select option
	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	jmp .more_select		; If not, wait for another key


.go_up:
	cmp dh, 7			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Row to select (increasing down)
	jmp .more_select


.go_down:				; Already at bottom of list?
	cmp dh, 20
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .more_select


.hit_top:
	mov byte cl, [.skip_num]	; Any lines to scroll up?
	cmp cl, 0
	je .another_key			; If not, wait for another key

	dec byte [.skip_num]		; If so, decrement lines to skip
	jmp .more_select


.hit_bottom:				; See if there's more to scroll
	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	inc byte [.skip_num]		; If so, increment lines to skip
	jmp .more_select



.option_selected:
	call os_show_cursor

	sub dh, 7

	mov ax, 0
	mov al, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	mov word [.tmp], ax		; Store option number before restoring all other regs

	popa

	mov word ax, [.tmp]
	clc				; Clear carry as Esc wasn't pressed
	ret



.esc_pressed:
	call os_show_cursor
	popa
	stc				; Set carry for Esc
	ret



.draw_list:
	pusha

	mov dl, 23			; Get into position for option list text
	mov dh, 7
	call os_move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	lodsb
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Counter for total number of options


.more:
	lodsb				; Get next character in file name, increment pointer

	cmp al, 0			; End of string?
	je .done_list

	cmp al, ','			; Next option? (String is comma-separated)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 23			; Go back to starting X position
	inc dh				; But jump down a line
	call os_move_cursor

	inc bx				; Update the number-of-options counter
	cmp bx, 14			; Limit to one screen of options
	jl .more

.done_list:
	popa
	call os_move_cursor

	ret



.draw_black_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 36
	mov bl, 00001111b		; White text on black background
	mov al, ' '
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 36
	mov bl, 11110000b		; Black text on white background
	mov al, ' '
	int 10h

	popa
	ret


	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0

option_screen:
	mov ax, os_init_msg		; Set up the welcome screen
	mov bx, os_version_msg

	mov cx, 00011111b		; Colour: white text on light blue
	call os_draw_background

	mov ax, dialog_string_1	
	mov bx, dialog_string_2
	mov cx, dialog_string_3
	mov dx, 0
	call os_dialog_box

	cmp ax, 1
	call os_print_newline
	call os_clear_screen

	call os_restart

	call mainloop

	jmp option_screen

os_get_cursor_pos:
	pusha

	mov bh, 0
	mov ah, 3
	int 10h				; BIOS interrupt to get cursor position

	mov [.tmp], dx
	popa
	mov dx, [.tmp]
	ret


	.tmp dw 0

os_print_horiz_line:
	pusha

	mov cx, ax			; Store line type param
	mov al, 196			; Default is single-line code

	cmp cx, 1			; Was double-line specified in AX?
	jne .ready
	mov al, 205			; If so, here's the code

.ready:
	mov cx, 0			; Counter
	mov ah, 0Eh			; BIOS output char routine

.restart:
	int 10h
	inc cx
	cmp cx, 80			; Drawn 80 chars yet?
	je .done
	jmp .restart

.done:
	popa
	ret

os_clear_screen:
	cli
   mov ax, 0
   mov ss, ax

   mov sp, 0FFFFh
   sti
   cld
   mov ax, 2000h
   mov ds, ax
   mov es, ax
   ;---	Color----;
   mov ax, 0x0700    ; function to scroll window
   mov bh, 0xd0    
   mov cx, 0x0000  ; row = 0, column = 0
   mov dx, 0x184f  ; row = 24 (0x18), column = 79 (0x4f)
   int 0x10

   mov ah, 09h
   mov cx, 1000h
   mov al, 20h
   mov bl, 17h
   int 10h
   ;-----End-----;
   mov cx, 10011111b

   mov si, welcome
   call print_string

   jmp mainloop

os_move_cursor:
	pusha

	mov bh, 0
	mov ah, 2
	int 10h				; BIOS interrupt to move cursor

	popa
	ret

os_draw_background:
	pusha

	push ax				; Store params to pop out later
	push bx
	push cx

	mov dl, 0
	mov dh, 0
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 80
	mov bl, 11111111b
	mov al, ' '
	int 10h

	mov dh, 1
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Draw colour section
	mov cx, 1840
	pop bx				; Get colour param (originally in CX)
	mov bh, 0
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Draw white bar at bottom
	mov bh, 0
	mov cx, 80
	mov bl, 11111111b
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 0
	call os_move_cursor
	pop bx				; Get bottom string param
	mov si, bx
	call print_string

	;========TITLE=BAR=========;

	mov bl, 10001111b		; White on Dark Grey
	mov dl, 20			; Start X position
	mov dh, 2			; Start Y position
	mov si, 40			; Width
	mov di, 23			; Finish Y position
	call os_draw_block		; Draw option selector window

	;==========CLOSE==========;

	mov dh, 2
	mov dl, 22
	call os_move_cursor
	pop ax				; Get top string param
	mov si, ax
	call print_string

	mov dh, 1			; Ready for app text
	mov dl, 0
	call os_move_cursor

	popa
	ret

os_dialog_box:
	pusha

	mov [.tmp], dx

	call os_hide_cursor

	mov dh, 9			; First, draw red background box
	mov dl, 19

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 42
	mov bl, 10011111b		; White on blue
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	cmp ax, 0			; Skip string params if zero
	je .no_first_string
	mov dl, 20
	mov dh, 10
	call os_move_cursor

	mov si, ax			; First string
	call print_string

.no_first_string:
	cmp bx, 0
	je .no_second_string
	mov dl, 20
	mov dh, 11
	call os_move_cursor

	mov si, bx			; Second string
	call print_string

.no_second_string:
	cmp cx, 0
	je .no_third_string
	mov dl, 20
	mov dh, 12
	call os_move_cursor

	mov si, cx			; Third string
	call print_string

.no_third_string:
	mov dx, [.tmp]
	cmp dx, 0
	je .one_button
	cmp dx, 1
	je .two_button


.one_button:
	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 35
	mov si, 10
	mov di, 15
	call os_draw_block

	mov dl, 38			; OK button, centred at bottom of box
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call print_string

	jmp .one_button_wait


.two_button:
	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 10
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call print_string

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call print_string

	mov cx, 0			; Default button = 0
	jmp .two_button_wait



.one_button_wait:
	call os_wait_for_key
	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .one_button_wait

	call os_show_cursor

	popa
	ret


.two_button_wait:
	call os_wait_for_key

	cmp ah, 75			; Left cursor key pressed?
	jne .noleft

	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 10
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call print_string

	mov bl, 01001111b		; White on red for cancel button
	mov dh, 14
	mov dl, 42
	mov si, 9
	mov di, 15
	call os_draw_block

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call print_string

	mov cx, 0			; And update result we'll return
	jmp .two_button_wait


.noleft:
	cmp ah, 77			; Right cursor key pressed?
	jne .noright


	mov bl, 01001111b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call print_string

	mov bl, 11110000b		; White on red for cancel button
	mov dh, 14
	mov dl, 43
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call print_string

	mov cx, 1			; And update result we'll return
	jmp .two_button_wait


.noright:
	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .two_button_wait

	call os_show_cursor

	mov [.tmp], cx			; Keep result after restoring all regs
	popa
	mov ax, [.tmp]

	ret


	.ok_button_string	db 'OK', 0
	.cancel_button_string	db 'Cancel', 0
	.ok_button_noselect	db '   OK   ', 0
	.cancel_button_noselect	db '   Cancel   ', 0

	.tmp dw 0

os_draw_block:
	pusha

.more:
	call os_move_cursor		; Move to block starting position

	mov ah, 09h			; Draw colour section
	mov bh, 0
	mov cx, si
	mov al, ' '
	int 10h

	inc dh				; Get ready for next line

	mov ax, 0
	mov al, dh			; Get current Y position into DL
	cmp ax, di			; Reached finishing point (DI)?
	jne .more			; If not, keep drawing

	popa
	ret

os_hide_cursor:
	pusha

	mov ch, 32
	mov ah, 1
	mov al, 3			; Must be video mode for buggy BIOSes!
	int 10h

	popa
	ret

os_show_cursor:
	pusha

	mov ch, 6
	mov cl, 7
	mov ah, 1
	mov al, 3
	int 10h

	popa
	ret

os_restart:
	cli
   	mov ax, 0
  	mov ss, ax

   	mov sp, 0FFFFh
  	sti
  	cld
 	mov ax, 2000h
 	mov ds, ax
  	mov es, ax
  	;---Color----;
   	mov ax, 0x0700    ; function to scroll window
 	mov bh, 0xd0    
  	mov cx, 0x0000  ; row = 0, column = 0
   	mov dx, 0x184f  ; row = 24 (0x18), column = 79 (0x4f)
   	int 0x10

  	mov ah, 09h
  	mov cx, 1000h
  	mov al, 20h
  	mov bl, 17h
  	int 10h
  	;-----End-----;
  	mov cx, 10011111b

  	mov si, welcome
  	call print_string

   	jmp mainloop


;===========================================;
exit db ' Press Esc to exit', 0
buttons db 'X', 0
os_init_msg db 'Welcome to the PixOS MenuLoader', 0
os_version_msg db 'Version 1.4', 0
dialog_string_1 db 'Welcome to PixOS!', 0
dialog_string_2 db 'Please proceed to the', 0
dialog_string_3	db 'PixOS command line.', 0
title times 32 db 0