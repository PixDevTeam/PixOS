;==================================DESKTOP============================;
draw_desktop:
	pusha

	mov bl, 01011111b		; White on grey
	mov dl, 0			; Start X position
	mov dh, 0			; Start Y position
	mov si, 80			; Width
	mov di, 26			; Finish Y position
	call os_draw_block		; Draw option selector window

	mov bl, 11110000b		; White on grey
	mov dl, 0			; Start X position
	mov dh, 0			; Start Y position
	mov si, 80			; Width
	mov di, 1			; Finish Y position
	call os_draw_block		; Draw option selector window

	mov dl, 0			; Show first line of help text...
	mov dh, 0
	call os_move_cursor

	mov si, .title
	call print_string

	popa
	ret

	.title		db 'PixOS Desktop', 0


os_desktop:
	call draw_desktop

	call os_desktop_items

os_desktop_items:
	pusha

	mov word [.filename], 0		; Terminate string in case user leaves without choosing

	mov ax, .buffer			; Get comma-separated list of filenames
	call os_get_file_list

	mov ax, .buffer			; Show those filenames in a list dialog box
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_desktop_file_grabber

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

	mov si, .filename
	call bin_file

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

os_desktop_file_grabber:
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

	mov dl, 0			; Show first line of help text...
	mov dh, 1
	call os_move_cursor

	pop si				; Get back first string

	inc dh				; ...and the second
	call os_move_cursor
	pop si

	pop si				; SI = location of option list string (pushed earlier)
	mov word [.list_string], si


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov dl, 0			; Set up starting position for selector
	mov dh, 1

	call os_move_cursor

.more_select:
	pusha
	mov bl, 11110000b		; Black on white for option list box
	mov dl, 21
	mov dh, 6

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
	mov bl, 01011111b		; Black text on white background
	mov al, ' '
	int 10h

	popa
	ret


	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0