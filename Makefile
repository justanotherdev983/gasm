game: game.o
	ld -o build/game src/game.o -dynamic-linker /lib64/ld-linux-x86-64.so.2 -L./raylib/ -lc -lraylib -lm

game.o: game.asm
	fasm src/game.asm
