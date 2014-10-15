org		0x7c00				; We are loaded by BIOS at 0x7C00
 
bits	16
 
mov	si, msg2
call    Print
mov	si, msg3
call    Print
call get_cmd
 
NewLine:
	pusha
 
	mov ah, 0Eh			; BIOS output char code
 
	mov al, 13
	int 10h
	mov al, 10
	int 10h
 
	popa
	ret
 
StartOS:
	cli					; Clear all Interrupts
	hlt					; halt the system
 
Print:
			lodsb				
			or	al, al			
			jz	PrintDone		
			mov	ah, 0eh	
			int	10h
			jmp	Print
 
	PrintDone:
			ret
 
msg db ">", 0x0D, 0x00
msg3 db "", 0x0A, 0x00
msg2 db "PixOS", 0x0D, 0x00
 
%INCLUDE "cmd.asm"
	
times 510-($-$$) db 0				; We have to be 512 bytes
 
dw 0xAA55					; Boot Signiture
