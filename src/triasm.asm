format ELF64

section '.text' executable

public _start

; External functions
extrn glfwInit
extrn glfwCreateWindow
extrn glfwMakeContextCurrent
extrn glewInit
extrn glViewport
extrn glGenVertexArrays
extrn glBindVertexArray
extrn glGenBuffers
extrn glBindBuffer
extrn glBufferData
extrn glCreateShader
extrn glShaderSource
extrn glCompileShader
extrn glCreateProgram
extrn glAttachShader
extrn glLinkProgram
extrn glDeleteShader
extrn glVertexAttribPointer
extrn glEnableVertexAttribArray
extrn glfwWindowShouldClose
extrn glClear
extrn glClearColor
extrn glUseProgram
extrn glDrawArrays
extrn glfwSwapBuffers
extrn glfwPollEvents
extrn glDeleteVertexArrays
extrn glDeleteBuffers
extrn glDeleteProgram
extrn glfwTerminate
extrn glGetError
extrn glGetShaderiv
extrn glGetShaderInfoLog
extrn glGetProgramiv
extrn glGetProgramInfoLog
extrn write

; Debug print macro
macro debug_print msg, len {
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, msg
    mov rdx, len
    syscall
}

; Error check macro for shaders
macro check_shader_compile shader, unique_id {
    push rbp
    mov rbp, rsp
    sub rsp, 520        ; 4 bytes for status + 512 for log + 4 padding

    ; Check compilation status
    mov rdi, [shader]
    mov rsi, 0x8B81     ; GL_COMPILE_STATUS
    lea rdx, [rbp-4]
    call glGetShaderiv

    cmp dword [rbp-4], 0
    jne .shader_success_#unique_id

    ; Get error log
    mov rdi, [shader]
    mov rsi, 512
    lea rdx, [rbp-8]    ; length return
    lea rcx, [rbp-520]  ; error message buffer
    call glGetShaderInfoLog

    ; Print error log
    debug_print error_shader_msg, error_shader_len
    mov rdx, [rbp-8]    ; length of error message
    mov rax, 1
    mov rdi, 1
    lea rsi, [rbp-520]
    syscall

    mov rdi, 1
    call exit_program

.shader_success_#unique_id:
    debug_print success_msg, success_len
    mov rsp, rbp
    pop rbp
}

; Error check macro for program linking
macro check_program_link program {
    push rbp
    mov rbp, rsp
    sub rsp, 520

    mov rdi, [program]
    mov rsi, 0x8B82     ; GL_LINK_STATUS
    lea rdx, [rbp-4]
    call glGetProgramiv

    cmp dword [rbp-4], 0
    jne @@link_success

    mov rdi, [program]
    mov rsi, 512
    lea rdx, [rbp-8]
    lea rcx, [rbp-520]
    call glGetProgramInfoLog

    debug_print error_link_msg, error_link_len
    mov rdx, [rbp-8]
    mov rax, 1
    mov rdi, 1
    lea rsi, [rbp-520]
    syscall

    mov rdi, 1
    call exit_program

@@link_success:
    debug_print link_success_msg, link_success_len
    mov rsp, rbp
    pop rbp
}

_start:
    ; Initialize GLFW
    debug_print init_glfw_msg, init_glfw_len
    call glfwInit
    test rax, rax
    jz error_exit

    ; Create window
    debug_print create_window_msg, create_window_len
    mov rdi, 800        ; width
    mov rsi, 600        ; height
    mov rdx, window_title
    xor rcx, rcx        ; monitor
    xor r8, r8          ; share
    call glfwCreateWindow
    test rax, rax
    jz error_exit
    mov [window], rax

    ; Make context current
    mov rdi, [window]
    call glfwMakeContextCurrent

    ; Initialize GLEW
    debug_print init_glew_msg, init_glew_len
    call glewInit
    test rax, rax       ; GLEW_OK is 0
    jnz error_exit


    ; Generate and bind VAO
    debug_print gen_bind_vao_msg, gen_bind_vao_len
    mov rdi, 1
    lea rsi, [vao]
    call glGenVertexArrays
    mov edi, [vao]
    call glBindVertexArray

    ; Generate and bind VBO
    debug_print gen_bind_vbo_msg, gen_bind_vbo_len
    mov rdi, 1
    lea rsi, [vbo]
    call glGenBuffers
    mov edi, 0x8892     ; GL_ARRAY_BUFFER
    mov esi, [vbo]
    call glBindBuffer

    ; Buffer data
    debug_print buffer_data_msg, buffer_data_len
    mov edi, 0x8892     ; GL_ARRAY_BUFFER
    mov rsi, 72         ; size (9 vertices * 4 bytes each)
    mov rdx, vertices
    mov rcx, 0x88E4     ; GL_STATIC_DRAW
    call glBufferData

    ; Create and compile vertex shader
    debug_print vertex_compile_msg, vertex_compile_len
    mov rdi, 0x8B31     ; GL_VERTEX_SHADER
    call glCreateShader
    mov [vertex_shader], rax

    push rbp
    mov rbp, rsp
    sub rsp, 8             ; Make space for pointer
    lea rax, [vertex_shader_source]
    mov [rsp], rax         ; Store pointer to shader source

    mov rdi, [vertex_shader]
    mov rsi, 1             ; count = 1
    mov rdx, rsp          ; pointer to array of strings (pointer to pointer)
    mov rcx, 0
    call glShaderSource

    mov rdi, [vertex_shader]
    call glCompileShader
    check_shader_compile vertex_shader, vertex

    ; Create and compile fragment shader
    debug_print fragment_compile_msg, fragment_compile_len
    mov edi, 0x8B30     ; GL_FRAGMENT_SHADER
    call glCreateShader
    mov [fragment_shader], rax

    ; Create a pointer to our shader source pointer on the stack
    push rbp
    mov rbp, rsp
    sub rsp, 8             ; Make space for pointer
    lea rax, [fragment_shader_source]
    mov [rsp], rax         ; Store pointer to shader source

    mov rdi, [fragment_shader]
    mov rsi, 1             ; count = 1
    mov rdx, rsp          ; pointer to array of strings (pointer to pointer)
    mov rcx, 0          ; lengths = NULL
    call glShaderSource

    mov rdi, [fragment_shader]
    call glCompileShader
    check_shader_compile fragment_shader, fragment

    ; Create and link shader program
    debug_print create_program_msg, create_program_len
    call glCreateProgram
    mov [shader_program], rax

    mov rdi, [shader_program]
    mov rsi, [vertex_shader]
    call glAttachShader

    mov rdi, [shader_program]
    mov rsi, [fragment_shader]
    call glAttachShader

    mov rdi, [shader_program]
    call glLinkProgram
    check_program_link shader_program

    ; Delete shaders
    debug_print delete_unused_shaders_msg, delete_unused_shaders_len
    mov rdi, [vertex_shader]
    call glDeleteShader
    mov rdi, [fragment_shader]
    call glDeleteShader

    ; Set vertex attributes
    debug_print set_vertex_attrib_msg, set_vertex_attrib_len
    mov rdi, 0          ; location
    mov rsi, 3          ; size
    mov rdx, 0x1406     ; GL_FLOAT
    xor rcx, rcx        ; normalized
    mov r8, 24          ; stride
    xor r9, r9          ; offset
    call glVertexAttribPointer
    mov rdi, 0
    call glEnableVertexAttribArray

    mov rdi, 1          ; location
    mov rsi, 3          ; size
    mov rdx, 0x1406     ; GL_FLOAT
    xor rcx, rcx        ; normalized
    mov r8, 24          ; stride
    mov r9, 12          ; offset
    call glVertexAttribPointer
    mov rdi, 1
    call glEnableVertexAttribArray

    debug_print render_msg, render_len

.render_loop:
    mov rdi, [window]
    call glfwWindowShouldClose
    test rax, rax
    jnz .cleanup

    mov edi, 0x4000     ; GL_COLOR_BUFFER_BIT
    call glClear

    mov rdi, [shader_program]
    call glUseProgram

    mov edi, 0x0004     ; GL_TRIANGLES
    xor rsi, rsi        ; first
    mov rdx, 3          ; count
    call glDrawArrays

    mov rdi, [window]
    call glfwSwapBuffers
    call glfwPollEvents
    jmp .render_loop

.cleanup:
    debug_print cleanup_msg, cleanup_len
    mov rdi, 1
    lea rsi, [vao]
    call glDeleteVertexArrays

    mov rdi, 1
    lea rsi, [vbo]
    call glDeleteBuffers

    mov rdi, [shader_program]
    call glDeleteProgram

    call glfwTerminate
    xor rdi, rdi
    jmp exit_program

error_exit:
    debug_print error_msg, error_len
    mov rdi, 1

exit_program:
    mov rax, 60         ; sys_exit
    syscall

section '.data' writeable

; Debug messages
init_glfw_msg db 'Initializing GLFW...', 10
init_glfw_len = $ - init_glfw_msg

create_window_msg db 'Creating window...', 10
create_window_len = $ - create_window_msg

init_glew_msg db 'Initializing GLEW...', 10
init_glew_len = $ - init_glew_msg

gen_bind_vao_msg db 'Generating and binding the VAO...', 10
gen_bind_vao_len = $ - gen_bind_vao_msg

gen_bind_vbo_msg db 'Generating and binding the VBO...', 10
gen_bind_vbo_len = $ - gen_bind_vbo_msg

buffer_data_msg db 'Putting necessary data into buffer...', 10
buffer_data_len = $ - buffer_data_msg

vertex_compile_msg db 'Compiling and creating vertex shader...', 10
vertex_compile_len = $ - vertex_compile_msg

fragment_compile_msg db 'Compiling and creating fragment shader...', 10
fragment_compile_len = $ - fragment_compile_msg

create_program_msg db 'Creating  and linking shader program...', 10
create_program_len = $ - create_program_msg

delete_unused_shaders_msg db 'Deleting unused shaders...', 10
delete_unused_shaders_len = $ - delete_unused_shaders_msg

set_vertex_attrib_msg db 'Setting the vertex attributes...', 10
set_vertex_attrib_len = $ - delete_unused_shaders_msg

error_shader_msg db 'Shader compilation failed:', 10
error_shader_len = $ - error_shader_msg

error_link_msg db 'Program linking failed:', 10
error_link_len = $ - error_link_msg

success_msg db 'Success!', 10
success_len = $ - success_msg

link_success_msg db 'Program linked successfully!', 10
link_success_len = $ - link_success_msg

render_msg db 'Entering render loop...', 10
render_len = $ - render_msg

cleanup_msg db 'Cleaning up...', 10
cleanup_len = $ - cleanup_msg

error_msg db 'An error occurred!', 10
error_len = $ - error_msg

window_title db 'OpenGL Triangle', 0

newline db 10

; Vertex data
vertices:
    dd 0.0, 0.5, 0.0,    1.0, 0.0, 0.0      ; Top (Red)
    dd -0.5, -0.5, 0.0,  0.0, 1.0, 0.0      ; Bottom Left (Green)
    dd 0.5, -0.5, 0.0,   0.0, 0.0, 1.0      ; Bottom Right (Blue)

; Shader sources
vertex_shader_source:
    db "#version 330 core", 10
    db "layout (location = 0) in vec3 aPos;", 10
    db "layout (location = 1) in vec3 aColor;", 10
    db "out vec3 ourColor;", 10
    db "void main()", 10
    db "{", 10
    db "    gl_Position = vec4(aPos, 1.0);", 10
    db "    ourColor = aColor;", 10
    db "}", 0

fragment_shader_source:
    db "#version 330 core", 10
    db "in vec3 ourColor;", 10
    db "out vec4 FragColor;", 10
    db "void main()", 10
    db "{", 10
    db "    FragColor = vec4(ourColor, 1.0);", 10
    db "}", 0

; Global variables
vao dd 0
vbo dd 0
vertex_shader dq 0
fragment_shader dq 0
shader_program dq 0
window dq 0