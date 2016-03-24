;=========================SYSTEM=CHECK==============================;
sys_check:
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

   mov di, syscheck1
   call add_check
   mov di, syschecktrue
   call add_value

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
   mov di, syschecktrue
   call add_value
   ;----END-COLOR--;

   mov ax, boot_file_string
   call os_file_exists
   jc .not_found

   mov di, syscheck3
   call add_check
   mov di, syschecktrue
   call add_value

   mov di, syscheck4
   call add_check
   call os_print_newline
   call os_wait_for_key

   mov si, boot_file_string
   call bin_file
   mov si, welcome
   call print_string

   jmp mainloop

.not_found:
   mov di, syscheck3
   call add_check
   mov di, syscheckfalse
   call add_value

   mov di, syscheck4
   call add_check
   call os_print_newline
   call os_wait_for_key

   mov cx, 10011111b

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

   call os_clear_screen
   mov si, welcome
   call print_string

   jmp mainloop

add_check:
   mov si, di
   call print_string
   
   ret

add_value:
   mov si, di
   mov  ah,  09h 
   mov  al,  97 
   mov  bx,  010b
   mov  cx,  01h 
   int  10h

   call print_string
   call os_print_newline
   call os_wait_for_key
   
   ret

;=====================CHECK=VARS=================================;
  syscheckkern db 'Kernel Version................................', 0
  syscheckver db 'System Version...............................', 0
  syscheck1 db 'KERNEL Loaded...................................', 0
  syscheckfalse db 'N', 0
  syschecktrue db 'Y', 0
  syscheck2_1 db 'C', 0
  syscheck2_2 db 'O', 0
  syscheck2_3 db 'L', 0
  syscheck2_4 db 'O', 0
  syscheck2_5 db 'R ', 0
  syscheck2_6 db 'Loaded....................................', 0
  syscheck3 db 'Boot Logo Loaded................................', 0
  syscheck4 db 'Ready for Boot. Press any key to continue.', 0