format ELF64

section '.text' executable

public _start
extrn InitWindow
extrn WindowShouldClose
extrn CloseWindow
extrn BeginDrawing
extrn EndDrawing
extrn _exit


_start:
	mov rdi, 600
	mov rsi, 601
	mov rdx, title
	call InitWindow

.game_loop:
	call WindowShouldClose
	test rax, rax
	jnz .cleanup
	
	call BeginDrawing
	call EndDrawing
	jmp .game_loop

.cleanup:
    call CloseWindow
  	mov rdi, 0
  	call _exit
 
section '.data' writeable

title: db "Gasm!!", 0
screen_x: dd 600, 0
screen_y: dd 600, 0

section '.note.GNU-stack'
