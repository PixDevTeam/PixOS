BITS 16

os_call_vectors:
	jmp main			; 0000h -- Called from bootloader
	jmp print_string		; 0003h
	jmp mainloop			; 0006h
	jmp get_string			; 0009h
	jmp cmd_loop			; 000Ch
	jmp os_print_newline		; 000Fh
	jmp os_load_file		; 0012h
	jmp os_string_tokenize		; 0015h
	jmp os_string_chomp		; 0018h
	jmp os_string_strincmp		; 001Bh
	jmp os_string_uppercase		; 001Eh
	jmp os_string_compare		; 0021h
	jmp os_string_length		; 0024h
	jmp os_string_parse		; 0027h
	jmp os_string_copy		; 002Ah
	jmp print_date			; 002Dh
	jmp print_time			; 0030h
	jmp os_set_time_fmt		; 0033h
	jmp os_string_find_char		; 0036h
	jmp os_get_time_string		; 0039h
	jmp os_get_date_string		; 003Ch
	jmp os_bcd_to_int		; 003Fh
	jmp os_wait_for_key		; 0042h
	jmp os_seed_random		; 0045h
	jmp os_get_random		; 0048h
	jmp os_clear_screen		; 004Bh
	jmp os_move_cursor		; 004Eh
	jmp os_get_cursor_pos		; 0051h
	jmp os_print_horiz_line		; 0054h
	jmp os_show_cursor		; 0057h
	jmp os_hide_cursor		; 005Ah
	jmp os_draw_block		; 005Dh
	jmp os_draw_background		; 0060h
	jmp os_dialog_box		; 0063h
	jmp os_restart			; 0066h
	jmp os_find_char_in_string	; 0069h
	jmp os_file_selector 		; 006Ch
	jmp os_list_dialog		; 006Fh
	;jmp 	; 0072h;
	;jmp 	; 0075h;
	;jmp 	; 0078h;
	;jmp 	; 007Bh;
	;jmp 	; 007Eh;


main:
   cli
   mov ax, 0
   mov ss, ax

   mov sp, 0FFFFh
   sti
   cld
   mov ax, 2000h
   mov ds, ax
   mov es, ax
   mov fs, ax
   mov gs, ax
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
   call cs_null
   ;-----SYS-CHECK-----;
   mov si, syscheckver
   call print_string
   mov si, version_num
   call print_string
   call os_wait_for_key

   mov si, syscheckkern
   call print_string
   mov si, kern_version_num
   call print_string
   call os_wait_for_key

   mov si, syscheck1
   call print_string
   call os_print_newline
   call os_wait_for_key
   ;-----COLOR-----;
   mov  ah,  09h 
   mov  al,  97 
   mov  bx,  100b
   mov  cx,  01h 
   int  10h

   mov si, syscheck2_1
   call print_string

   mov  ah,  09h 
   mov  al,  97 
   mov  bx,  010b
   mov  cx,  01h 
   int  10h

   mov si, syscheck2_2
   call print_string

   mov  ah,  09h 
   mov  al,  97 
   mov  bx,  1110b
   mov  cx,  01h 
   int  10h

   mov si, syscheck2_3
   call print_string

   mov  ah,  09h 
   mov  al,  97 
   mov  bx,  1b
   mov  cx,  01h 
   int  10h

   mov si, syscheck2_4
   call print_string

   mov  ah,  09h 
   mov  al,  97 
   mov  bx,  101b
   mov  cx,  01h 
   int  10h

   mov si, syscheck2_5
   call print_string

   mov si, syscheck2_6
   call print_string

   call os_print_newline
   call os_wait_for_key
   ;----END-COLOR--;
   mov ax, boot_file_string
   call os_file_exists
   jc not_found

   mov si, syscheck3
   call print_string
   call os_print_newline
   call os_wait_for_key

   mov si, syscheck4
   call print_string
   call os_print_newline
   call os_wait_for_key
	
   ;-END-SYS-CHECK-----;

   mov cx, 10011111b

   mov si, boot_file_string
   call bin_file
   mov si, welcome
   call print_string

   jmp mainloop

not_found:
   mov si, syscheck3n
   call print_string
   call os_print_newline
   call os_wait_for_key

   mov si, syscheck4
   call print_string
   call os_print_newline
   call os_wait_for_key

   mov cx, 10011111b

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

   call os_clear_screen
   mov si, welcome
   call print_string

   jmp mainloop

mainloop:
   mov di, buffer			; Clear input buffer each time
   mov al, 0
   mov cx, 256
   rep stosb

   mov di, command			; And single command buffer
   mov cx, 32
   rep stosb

   mov si, prompt
   call print_string
 
   mov di, buffer
   call get_string

   mov ax, buffer			; Remove trailing spaces
   call os_string_chomp
 
   mov si, buffer
   cmp byte [si], 0  ; blank line?
   je mainloop       ; yes, ignore it
   mov si, buffer
   mov al, ' '
   call os_string_tokenize
   mov word [param_list], di
   mov si, buffer

   mov di, command
   call os_string_copy
   jmp cmd_loop
 
 get_string:
   xor cl, cl
 
 .loop:
   mov ah, 0
   int 0x16   ; wait for keypress
 
   cmp al, 0x08    ; backspace pressed?
   je .backspace   ; yes, handle it
 
   cmp al, 0x0D  ; enter pressed?
   je .done      ; yes, we're done
 
   cmp cl, 0x3F  ; 63 chars inputted?
   je .loop      ; yes, only let in backspace and enter
 
   mov ah, 0x0E
   int 0x10      ; print out character
 
   stosb  ; put character in buffer
   inc cl
   jmp .loop
 
 .backspace:
   cmp cl, 0	; beginning of string?
   je .loop	; yes, ignore the key
 
   dec di
   mov byte [di], 0	; delete character
   dec cl		; decrement counter as well
 
   mov ah, 0x0E
   mov al, 0x08
   int 10h		; backspace on the screen
 
   mov al, ' '
   int 10h		; blank character out
 
   mov al, 0x08
   int 10h		; backspace again
 
   jmp .loop	; go to the main loop
 
 .done:
   mov al, 0	; null terminator
   stosb
 
   mov ah, 0x0E
   mov al, 0x0D
   int 0x10
   mov al, 0x0A
   int 0x10		; newline
 
   ret

  syscheckkern db 'Kernel Version...................................', 0
  syscheckver db 'System Version..................................', 0
  syscheck1 db 'KERNEL Loaded...................................TRUE', 0
  syscheck2_1 db 'C', 0
  syscheck2_2 db 'O', 0
  syscheck2_3 db 'L', 0
  syscheck2_4 db 'O', 0
  syscheck2_5 db 'R ', 0
  syscheck2_6 db 'Loaded....................................TRUE', 0
  syscheck3 db 'Boot Logo Loaded................................TRUE', 0
  syscheck3n db 'Boot Logo Loaded...............................FALSE', 0
  syscheck4 db 'Ready for Boot. Press any key to continue.', 0
 
  %INCLUDE "cmd/cmd.asm"
  %INCLUDE "cmd/disk_cmd.asm"
  %INCLUDE "cmd/cmdloop.asm"
  %INCLUDE "cmd/date_time.asm"
  %INCLUDE "cmd/strings.asm"
  %INCLUDE "cmd/gui.asm"