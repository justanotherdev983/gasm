cmake_minimum_required(VERSION 3.10)
project(gasm)

add_custom_command(
    OUTPUT game.o
    COMMAND /bin/fasm ${CMAKE_SOURCE_DIR}/src/game.asm game.o
    DEPENDS ${CMAKE_SOURCE_DIR}/src/game.asm
)

add_custom_target(game ALL
    COMMAND ld -o ${CMAKE_BINARY_DIR}/game game.o 
        -dynamic-linker /lib64/ld-linux-x86-64.so.2 
        -L./lib/raylib -lc -lraylib -lm
    DEPENDS game.o
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

install(FILES ${CMAKE_BINARY_DIR}/game DESTINATION bin)