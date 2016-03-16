;===========CMDS=====================;
ren_file:
	mov word si, [param_list]
	call os_string_parse

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call print_string
	jmp mainloop

.filename_provided:
	mov cx, ax			; Store first filename temporarily
	mov ax, bx			; Get destination
	call os_file_exists		; Check to see if it exists
	jnc .already_exists

	mov ax, cx			; Get first filename back
	call os_rename_file
	jc .failure

	mov si, .success_msg
	call print_string
	jmp mainloop

.already_exists:
	mov si, exists_msg
	call print_string
	jmp mainloop

.failure:
	mov si, .failure_msg
	call print_string
	jmp mainloop


	.success_msg	db 'File renamed successfully', 13, 10, 0
	.failure_msg	db 'Operation failed - file not found or invalid filename', 13, 10, 0

del_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call print_string
	jmp mainloop

.filename_provided:
	call os_remove_file
	jc .failure

	mov si, .success_msg
	call print_string
	mov si, ax
	call print_string
	call os_print_newline
	jmp mainloop

.failure:
	mov si, .failure_msg
	call print_string
	jmp mainloop


	.success_msg	db 'File Removed', 0
	.failure_msg	db 'Could not remove file - does not exist or write protected', 13, 10, 0

size_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call print_string
	jmp mainloop

.filename_provided:
	call os_get_file_size
	jc .failure

	mov ax, bx
	call os_int_to_string
	mov si, ax
	call print_string
	call os_print_newline
	jmp mainloop

	mov si, .size_msg
	call print_string


.failure:
	mov si, notfound_msg
	call print_string
	jmp mainloop


	.size_msg	db ' Bytes', 0

run_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			; Was a filename provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call print_string
	jmp mainloop

.filename_provided:
	call bin_file
	jc .failure

	call os_print_newline
	jmp mainloop

.failure:
	mov si, notfound_msg
	call print_string
	jmp mainloop


copy_file:
	mov word si, [param_list]
	call os_string_parse
	mov word [.tmp], bx

	cmp bx, 0			; Were two filenames provided?
	jne .filename_provided

	mov si, nofilename_msg		; If not, show error message
	call print_string
	jmp mainloop

.filename_provided:
	mov dx, ax			; Store first filename temporarily
	mov ax, bx
	call os_file_exists
	jnc .already_exists

	mov ax, dx
	mov cx, 32768
	call os_load_file
	jc .load_fail

	mov cx, bx
	mov bx, 32768
	mov word ax, [.tmp]
	call os_write_file
	jc .write_fail

	mov si, .success_msg
	call print_string
	jmp mainloop

.load_fail:
	mov si, notfound_msg
	call print_string
	jmp mainloop

.write_fail:
	mov si, writefail_msg
	call print_string
	jmp mainloop

.already_exists:
	mov si, exists_msg
	call print_string
	jmp mainloop


	.tmp		dw 0
	.success_msg	db 'File copied successfully', 13, 10, 0

bin_file:
	mov ax, si
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

	jmp execute_bin

execute_bin:
	mov si, ax
	mov di, kern_file_string
	mov cx, 6
	call os_string_strincmp
	jc kernel_no_run

	mov ax, 0			; Clear all registers
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov word si, [param_list]
	mov di, 0

	call 32768			; Call the external program

	jmp mainloop

total_fail:
	mov si, invalid_msg
	call print_string

	jmp mainloop

kernel_no_run:
	mov si, kern_warn_msg
	call print_string

	jmp mainloop
strcmp:
 .loop:
   mov al, [si]   ; grab a byte from SI
   mov bl, [di]   ; grab a byte from DI
   cmp al, bl     ; are they equal?
   jne .notequal  ; nope, we're done.
 
   cmp al, 0  ; are both bytes (they were equal before) null?
   je .done   ; yes, we're done.
 
   inc di     ; increment DI
   inc si     ; increment SI
   jmp .loop  ; loop!
 
 .notequal:
   clc  ; not equal, clear the carry flag
   ret
 
 .done: 	
   stc  ; equal, set the carry flag
   ret


print_string:
   lodsb        ; grab a byte from SI
 
   or al, al  ; logical or AL by itself
   jz .done   ; if the result is zero, get out
 
   mov ah, 0x0E
   int 0x10      ; otherwise, print out the character!
 
   jmp print_string

.done:
   ret

cs_g:
  pusha

  mov ax, 0x0700    ; function to scroll window
  mov bh, 0xa0    
  mov cx, 0x0000  ; row = 0, column = 0
  mov dx, 0x184f  ; row = 24 (0x18), column = 79 (0x4f)
  int 0x10        ; call the BIOS interrupt

  popa
  ret

cs_r:
  pusha

  mov ax, 0x0700    ; function to scroll window
  mov bh, 0x40    
  mov cx, 0x0000  ; row = 0, column = 0
  mov dx, 0x184f  ; row = 24 (0x18), column = 79 (0x4f)
  int 0x10        ; call the BIOS interrupt

  popa
  ret

cs_b:
  pusha

  mov ax, 0x0700    ; function to scroll window
  mov bh, 0x90    
  mov cx, 0x0000  ; row = 0, column = 0
  mov dx, 0x184f  ; row = 24 (0x18), column = 79 (0x4f)
  int 0x10        ; call the BIOS interrupt

  popa
  ret

cs_y:
  pusha

  mov ax, 0x0700    ; function to scroll window
  mov bh, 0xe0    
  mov cx, 0x0000  ; row = 0, column = 0
  mov dx, 0x184f  ; row = 24 (0x18), column = 79 (0x4f)
  int 0x10        ; call the BIOS interrupt

  popa
  ret


;===========VARS====================;
 ;logo1 db ' ___  __  _  _ ', 0x0D, 0x0A, 0
 ;logo2 db '||_|| ||  \\// ', 0x0D, 0x0A, 0
 ;logo3 db '||    ||  //\\ ', 0x0D, 0x0A, 0
 ;logo4 db '---------------', 0x0D, 0x0A, 0
 welcome db 'Welcome to the PixKernel', 0x0D, 0x0A, 0
 msg_version db 'Pix OS 1.42', 0x0D, 0x0A, 0
 kern_version db 'PixKern 2.0', 0x0D, 0x0A, 0
 badcommand db 'No Existing Command :', 0x0D, 0x0A, 0
 num1 equ 1
 num2 equ 2
 prompt db '>', 0
 cmd_version db 'VERSION', 0
 cmd_help db 'HELP', 0
 cmd_size db 'SIZE', 0
 cmd_cls db 'CLS', 0
 cmd_ls db 'LS', 0
 cmd_vol db 'VOL', 0
 cmd_test db 'TEST', 0
 cmd_rm db 'RM', 0
 cmd_run db 'BASH', 0
 cmd_edit db 'EDIT', 0
 cmd_date db 'DATE', 0
 cmd_time db 'TIME', 0
 cmd_col db 'COLOR', 0
 cmd_cs_g db 'COLOR -G', 0
 cmd_cs_b db 'COLOR -B', 0
 cmd_cs_r db 'COLOR -R', 0
 cmd_cs_y db 'COLOR -Y', 0
 msg_help db 'Commands: version, help, ls, vol, rm, size, edit, color, time, bash', 0x0D, 0x0A, 0
 msg_col db 'Need more Parameters', 0x0D, 0x0A, 0
 msg_col2 db '-g : green', 0x0D, 0x0A, 0
 msg_col3 db '-r : red', 0x0D, 0x0A, 0
 msg_col4 db '-b : blue', 0x0D, 0x0A, 0
 msg_col5 db '-y : yellow', 0x0D, 0x0A, 0
 buffer	equ 24576
 kern_file_string db 'KERNEL.BIN', 0
 edit_file_string db 'EDIT.BIN', 0
 time_file_string db 'TIME.BIN', 0
 boot_file_string db 'BOOTLOGO.BIN', 0
 prog_file_string db 'TEST.BIN', 0
 kern_warn_msg db 'The Kernel is not an executable file!', 13, 10, 0
 vol_label_string db 'Disk Name: ', 0
 vol_fs_string	db 'Filesystem: ', 0
 notfound_msg db 'File does not Exist', 13, 10, 0
 invalid_msg db 'No such command or program', 13, 10, 0
 exists_msg db 'Target file already exists!', 13, 10, 0
 writefail_msg db 'Write fail. Read-only or invalid name', 13, 10, 0
 nofilename_msg db 'No filename or not enough filenames', 13, 10, 0
 param_list dw 0
 dirlist times 1024 db 0
 Sides dw 2
 SecsPerTrack dw 18
 bootdev db 0
 tmp_string times 15 db 0
 fmt_date db 0, '/'
 fmt_12_24 db 0, '/'
 dest_string times 13 db 0
 bin_extension db '.BIN', 0
 disk_buffer equ 24576
 command times 32 db 0
 boot_pic_string db 'boot.pcx', 0