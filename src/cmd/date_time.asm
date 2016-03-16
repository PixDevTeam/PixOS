;=========TIME/DATE=========;
print_date:
	pusha

	mov bx, tmp_string
	call os_get_date_string
	mov si, bx
	call print_string
	call os_print_newline

	popa
        ret

print_time:
	pusha

	mov bx, tmp_string
	call os_get_time_string
	mov si, bx
	call print_string
	call os_print_newline

	popa
        ret

os_set_time_fmt:
	pusha
	cmp al, 0
	je .store
	mov al, 0FFh
.store:
	mov [fmt_12_24], al
	popa
	ret

os_get_time_string:
	pusha

	mov di, bx			; Location to place time string

	clc				; For buggy BIOSes
	mov ah, 2			; Get time data from BIOS in BCD format
	int 1Ah
	jnc .read

	clc
	mov ah, 2			; BIOS was updating (~1 in 500 chance), so try again
	int 1Ah

.read:
	mov al, ch			; Convert hours to integer for AM/PM test
	call os_bcd_to_int
	mov dx, ax			; Save

	mov al,	ch			; Hour
	shr al, 4			; Tens digit - move higher BCD number into lower bits
	and ch, 0Fh			; Ones digit
	test byte [fmt_12_24], 0FFh
	jz .twelve_hr

	call .add_digit			; BCD already in 24-hour format
	mov al, ch
	call .add_digit
	jmp short .minutes

.twelve_hr:
	cmp dx, 0			; If 00mm, make 12 AM
	je .midnight

	cmp dx, 10			; Before 1000, OK to store 1 digit
	jl .twelve_st1

	cmp dx, 12			; Between 1000 and 1300, OK to store 2 digits
	jle .twelve_st2

	mov ax, dx			; Change from 24 to 12-hour format
	sub ax, 12
	mov bl, 10
	div bl
	mov ch, ah

	cmp al, 0			; 1-9 PM
	je .twelve_st1

	jmp short .twelve_st2		; 10-11 PM

.midnight:
	mov al, 1
	mov ch, 2

.twelve_st2:
	call .add_digit			; Modified BCD, 2-digit hour
.twelve_st1:
	mov al, ch
	call .add_digit

	mov al, ':'			; Time separator (12-hr format)
	stosb

.minutes:
	mov al, cl			; Minute
	shr al, 4			; Tens digit - move higher BCD number into lower bits
	and cl, 0Fh			; Ones digit
	call .add_digit
	mov al, cl
	call .add_digit

	mov al, ' '			; Separate time designation
	stosb

	mov si, .hours_string		; Assume 24-hr format
	test byte [fmt_12_24], 0FFh
	jnz .copy

	mov si, .pm_string		; Assume PM
	cmp dx, 12			; Test for AM/PM
	jg .copy

	mov si, .am_string		; Was actually AM

.copy:
	lodsb				; Copy designation, including terminator
	stosb
	cmp al, 0
	jne .copy

	popa
	ret


.add_digit:
	add al, '0'			; Convert to ASCII
	stosb				; Put into string buffer
	ret


	.hours_string	db 'hours', 0
	.am_string 	db 'AM', 0
	.pm_string 	db 'PM', 0

os_get_date_string:
	pusha

	mov di, bx			; Store string location for now
	mov bx, [fmt_date]		; BL = format code
	and bx, 7F03h			; BH = separator, 0 = use month names

	clc				; For buggy BIOSes
	mov ah, 4			; Get date data from BIOS in BCD format
	int 1Ah
	jnc .read

	clc
	mov ah, 4			; BIOS was updating (~1 in 500 chance), so try again
	int 1Ah

.read:
	cmp bl, 2			; YYYY/MM/DD format, suitable for sorting
	jne .try_fmt1

	mov ah, ch			; Always provide 4-digit year
	call .add_2digits
	mov ah, cl
	call .add_2digits		; And '/' as separator
	mov al, '/'
	stosb

	mov ah, dh			; Always 2-digit month
	call .add_2digits
	mov al, '/'			; And '/' as separator
	stosb

	mov ah, dl			; Always 2-digit day
	call .add_2digits
	jmp .done

.try_fmt1:
	cmp bl, 1			; D/M/Y format (military and Europe)
	jne .do_fmt0

	mov ah, dl			; Day
	call .add_1or2digits

	mov al, bh
	cmp bh, 0
	jne .fmt1_day

	mov al, ' '			; If ASCII months, use space as separator

.fmt1_day:
	stosb				; Day-month separator

	mov ah,	dh			; Month
	cmp bh, 0			; ASCII?
	jne .fmt1_month

	call .add_month			; Yes, add to string
	mov ax, ', '
	stosw
	jmp short .fmt1_century

.fmt1_month:
	call .add_1or2digits		; No, use digits and separator
	mov al, bh
	stosb

.fmt1_century:
	mov ah,	ch			; Century present?
	cmp ah, 0
	je .fmt1_year

	call .add_1or2digits		; Yes, add it to string (most likely 2 digits)

.fmt1_year:
	mov ah, cl			; Year
	call .add_2digits		; At least 2 digits for year, always

	jmp short .done

.do_fmt0:				; Default format, M/D/Y (US and others)
	mov ah,	dh			; Month
	cmp bh, 0			; ASCII?
	jne .fmt0_month

	call .add_month			; Yes, add to string and space
	mov al, ' '
	stosb
	jmp short .fmt0_day

.fmt0_month:
	call .add_1or2digits		; No, use digits and separator
	mov al, bh
	stosb

.fmt0_day:
	mov ah, dl			; Day
	call .add_1or2digits

	mov al, bh
	cmp bh, 0			; ASCII?
	jne .fmt0_day2

	mov al, ','			; Yes, separator = comma space
	stosb
	mov al, ' '

.fmt0_day2:
	stosb

.fmt0_century:
	mov ah,	ch			; Century present?
	cmp ah, 0
	je .fmt0_year

	call .add_1or2digits		; Yes, add it to string (most likely 2 digits)

.fmt0_year:
	mov ah, cl			; Year
	call .add_2digits		; At least 2 digits for year, always


.done:
	mov ax, 0			; Terminate date string
	stosw

	popa
	ret


.add_1or2digits:
	test ah, 0F0h
	jz .only_one
	call .add_2digits
	jmp short .two_done
.only_one:
	mov al, ah
	and al, 0Fh
	call .add_digit
.two_done:
	ret

.add_2digits:
	mov al, ah			; Convert AH to 2 ASCII digits
	shr al, 4
	call .add_digit
	mov al, ah
	and al, 0Fh
	call .add_digit
	ret

.add_digit:
	add al, '0'			; Convert AL to ASCII
	stosb				; Put into string buffer
	ret

.add_month:
	push bx
	push cx
	mov al, ah			; Convert month to integer to index print table
	call os_bcd_to_int
	dec al				; January = 0
	mov bl, 4			; Multiply month by 4 characters/month
	mul bl
	mov si, .months
	add si, ax
	mov cx, 4
	rep movsb
	cmp byte [di-1], ' '		; May?
	jne .done_month			; Yes, eliminate extra space
	dec di
.done_month:
	pop cx
	pop bx
	ret


	.months db 'Jan.Feb.Mar.Apr.May JuneJulyAug.SeptOct.Nov.Dec.'

os_bcd_to_int:
	pusha

	mov bl, al			; Store entire number for now

	and ax, 0Fh			; Zero-out high bits
	mov cx, ax			; CH/CL = lower BCD number, zero extended

	shr bl, 4			; Move higher BCD number into lower bits, zero fill msb
	mov al, 10
	mul bl				; AX = 10 * BL

	add ax, cx			; Add lower BCD to 10*higher
	mov [.tmp], ax

	popa
	mov ax, [.tmp]			; And return it in AX!
	ret


	.tmp	dw 0