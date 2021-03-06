cmd_loop:
   mov ax, buffer
   call os_string_uppercase

   mov si, buffer

   mov di, cmd_help  		; 'HELP' command
   call strcmp
   jc near .help

   mov si, buffer

   mov di, cmd_ls		; 'LS' command
   call strcmp
   jc near .ls

   mov si, buffer

   mov di, cmd_desktop		; STARTX
   call strcmp
   jc near .desktop

   mov si, buffer

   mov di, cmd_test		; 'TEST' command
   call strcmp
   jc near .test

   mov si, buffer

   mov di, cmd_edit		; 'EDIT' command
   call strcmp
   jc near .edit

   mov si, buffer

   mov si, buffer
   mov di, cmd_rm		; 'RM' command
   call strcmp
   jc near .rm

   mov si, buffer

   mov di, cmd_vol		; 'VOL' command
   call strcmp
   jc near .vol

   mov si, buffer

   mov di, cmd_time		; 'TIME' command
   call strcmp
   jc near .time

   mov si, buffer

   mov di, cmd_shutdown		; 'SHUTDOWN' command
   call strcmp
   jc near .shutdown

   mov si, buffer

   mov di, cmd_col		; 'COLOR' command
   call strcmp
   jc near .col

   mov si, buffer

   mov di, cmd_size		; 'SIZE' command
   call strcmp
   jc near .size

   mov si, buffer

   mov di, cmd_run		; 'RUN' command
   call strcmp
   jc near .run

   mov si, badcommand
   call print_string
   mov si, buffer		; BAD COMMAND
   call print_string
   call os_print_newline
   jmp mainloop

 .help:
    mov si, msg_help
    call print_string
 
    jmp mainloop

 .col:
   mov si, msg_col
   call print_string
   mov si, msg_col2
   call print_string
   mov si, msg_col3
   call print_string
   mov si, msg_col4
   call print_string
   mov si, msg_col5
   call print_string

  jmp mainloop

 ;.cs_g:
  ;call cs_g

  ;jmp mainloop 

 .ls:
  call list_directory

  jmp mainloop

 .desktop:
  call os_desktop

  jmp mainloop

 .shutdown:
  call shutdown

  jmp mainloop

 .rm:
  call del_file

  jmp mainloop

 .run:
  mov bl, 00001111b
  mov dl, 0
  mov dh, 0
  mov si, 80
  mov di, 25
  call os_draw_block

  call run_file
  call os_print_newline

  jmp mainloop

 .test:
  mov si, prog_file_string
  call bin_file
  call os_print_newline

  jmp mainloop

.edit:
  mov si, edit_file_string
  call bin_file
  call os_print_newline

  jmp mainloop

 .vol:
  call print_vol

  jmp mainloop

 .size:
  call size_file

  jmp mainloop

 .time:
  call print_time
  call print_date

  jmp mainloop