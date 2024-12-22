cmake_minimum_required(VERSION 3.10)
project(triasm)

# Define GLAD source and include directory
set(GLAD_SRC ${CMAKE_SOURCE_DIR}/src/glad.c)
set(GLAD_INCLUDE ${CMAKE_SOURCE_DIR}/src)

# Set GLFW include and library directories
set(GLFW_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/libs/glfw/include)
set(GLFW_LIB_DIR ${CMAKE_SOURCE_DIR}/libs/glfw/lib)

# Set GLEW include and library directories
set(GLEW_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/libs/glew/include)
set(GLEW_LIB_DIR ${CMAKE_SOURCE_DIR}/libs/glew/lib)

# Create custom command to build the assembly code
add_custom_command(
        OUTPUT triasm.o
        COMMAND /bin/fasm ${CMAKE_SOURCE_DIR}/src/triasm.asm triasm.o
        DEPENDS ${CMAKE_SOURCE_DIR}/src/triasm.asm
)

# Create custom target to link everything together
add_custom_target(triasm ALL
        COMMAND ld -o ${CMAKE_BINARY_DIR}/triasm triasm.o
        -dynamic-linker /lib64/ld-linux-x86-64.so.2
        -L${GLFW_LIB_DIR} -L${GLEW_LIB_DIR} -lglfw -lGLEW -lGL -g -lm -lc -lX11 -lpthread -ldl
        DEPENDS triasm.o
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

# Install the compiled binary to the bin directory
install(FILES ${CMAKE_BINARY_DIR}/triasm DESTINATION bin)