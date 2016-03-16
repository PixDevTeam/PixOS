;============================PIX=OS=API=================================;
;============================VERSION 1.55================================;

; ------------------------------------------------------------------
; SYSTEM CALLS
; ------------------------------------------------------------------
; COLOURS
; ------------------------------------------------------------------

%DEFINE BLACK_ON_WHITE		11110000b
%DEFINE WHITE_ON_BLACK		00001111b
%DEFINE WHITE_ON_LIGHT_RED	11001111b
%DEFINE WHITE_ON_GREEN		00101111b
%DEFINE RED_ON_LIGHT_GREEN	10100100b

; ------------------------------------------------------------------
; KEYS
; ------------------------------------------------------------------

%DEFINE KEY_UP		72
%DEFINE KEY_DOWN	80
%DEFINE KEY_LEFT	75
%DEFINE KEY_RIGHT	77

%DEFINE KEY_ESC		27
%DEFINE KEY_ENTER	13


; ------------------------------------------------------------------
print_string		equ	0003h
os_print_string		equ	0003h
mainloop		equ	0006h
get_string		equ	0009h
cmd_loop		equ	000Ch
os_print_newline	equ	000Fh
os_load_file		equ	0012h
os_string_tokenize	equ	0015h
os_string_chomp		equ	0018h
os_string_strincmp	equ	001Bh
os_string_uppercase	equ	001Eh
os_string_compare	equ	0021h
os_string_length	equ	0024h
os_string_parse		equ	0027h
os_string_copy		equ	002Ah
print_date		equ	002Dh
print_time		equ	0030h
os_set_time_fmt		equ	0033h
os_string_find_char	equ	0036h
os_get_time_string	equ	0039h
os_get_date_string	equ	003Ch
os_bcd_to_int		equ	003Fh
os_wait_for_key		equ	0042h
os_seed_random		equ	0045h
os_get_random		equ	0048h
os_clear_screen		equ	004Bh
os_move_cursor		equ	004Eh
os_get_cursor_pos	equ	0051h
os_print_horiz_line	equ	0054h
os_show_cursor		equ	0057h
os_hide_cursor		equ	005Ah
os_draw_block		equ	005Dh
os_draw_background	equ	0060h
os_dialog_box		equ	0063h
os_restart		equ	0066h
os_find_char_in_string	equ	0069h
os_file_selector 	equ	006Ch
;=======================================================================;
