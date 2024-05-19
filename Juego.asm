.section .data
filename: .asciz "palabras.txt"
buffer: .space 1024
palabras: .space 1024
palabra_oculta: .space 64
letras_adivinadas: .space 26
intentos_restantes: .word 6
ranking_filename: .asciz "ranking.txt"
ranking_buffer: .space 1024

.section .text
.global _start

_start:
    bl leer_palabras
    bl sortear_palabra
    bl imprimir_mapa
    bl leer_letra
    bl mostrar_ranking
    bl grabar_ranking

    mov r7, #1          @ sys_exit
    mov r0, #0
    svc #0

leer_palabras:
    @ Abrir el archivo
    ldr r0, =filename
    mov r1, #0          @ O_RDONLY
    mov r7, #5          @ sys_open
    svc #0
    mov r4, r0          @ Guardar el file descriptor

    @ Leer el archivo
    mov r0, r4          @ file descriptor
    ldr r1, =buffer     @ buffer
    mov r2, #1024       @ tamaño del buffer
    mov r7, #3          @ sys_read
    svc #0

    @ Cerrar el archivo
    mov r0, r4          @ file descriptor
    mov r7, #6          @ sys_close
    svc #0

    @ Copiar el contenido del buffer a palabras
    ldr r0, =buffer
    ldr r1, =palabras
    mov r2, #1024
copy_loop:
    subs r2, r2, #1
    ldrb r3, [r0], #1
    strb r3, [r1], #1
    bne copy_loop
    bx lr

sortear_palabra:
    @ Simulamos la elección de una palabra aleatoria
    ldr r0, =palabras
    mov r1, #0  @ Índice de palabra seleccionada (en este ejemplo, siempre la primera palabra)
    bl obtener_palabra
    bx lr

obtener_palabra:
    @ Copiar palabra de `palabras` a `palabra_oculta`
    ldr r2, =palabra_oculta
    mov r3, r0
find_space:
    ldrb r4, [r3], #1
    cmp r4, #32         @ Espacio como delimitador
    beq copy_word
    cmp r4, #0
    beq copy_word
    b find_space

copy_word:
    ldrb r4, [r0], #1
    strb r4, [r2], #1
    cmp r4, #32
    beq end_copy
    cmp r4, #0
    beq end_copy
    b copy_word

end_copy:
    bx lr

imprimir_mapa:
    ldr r0, =palabra_oculta
    ldr r1, =letras_adivinadas
    mov r2, #64

print_mapa_loop:
    ldrb r3, [r0], #1
    cmp r3, #0
    beq print_newline
    mov r4, r1
    mov r5, #26
check_letter_loop:
    ldrb r6, [r4], #1
    cmp r6, r3
    beq print_letter
    subs r5, r5, #1
    bne check_letter_loop
    mov r6, #95   @ '_'
    b print_char

print_letter:
    mov r6, r3
print_char:
    mov r0, r6
    bl putchar
    b print_mapa_loop

print_newline:
    mov r0, #10
    bl putchar
    bx lr

putchar:
    push {r1, r2, r7}  @ Guardar registros
    mov r1, r0         @ Caracter a imprimir
    mov r2, #1         @ stdout
    mov r7, #4         @ sys_write
    svc #0
    pop {r1, r2, r7}   @ Restaurar registros
    bx lr

leer_letra:
    mov r7, #3       @ sys_read
    mov r0, #0       @ stdin
    ldr r1, =buffer  @ Leer una letra al buffer
    mov r2, #1
    svc #0
    ldrb r0, [r1]
    bx lr

mostrar_ranking:
    @ Abrir el archivo de ranking
    ldr r0, =ranking_filename
    mov r1, #0          @ O_RDONLY
    mov r7, #5          @ sys_open
    svc #0
    mov r4, r0          @ Guardar el file descriptor

    @ Leer el archivo
    mov r0, r4          @ file descriptor
    ldr r1, =ranking_buffer @ buffer
    mov r2, #1024       @ tamaño del buffer
    mov r7, #3          @ sys_read
    svc #0

    @ Cerrar el archivo
    mov r0, r4          @ file descriptor
    mov r7, #6          @ sys_close
    svc #0

    @ Imprimir el ranking
    ldr r0, =ranking_buffer
    bl print_string
    bx lr

print_string:
    push {r1, r2, r7}  @ Guardar registros

print_char_loop:
    ldrb r1, [r0], #1  @ Cargar el siguiente byte
    cmp r1, #0         @ Comparar con nulo
    beq print_done     @ Si es nulo, terminar
    mov r2, #1         @ stdout
    mov r7, #4         @ sys_write
    svc #0
    b print_char_loop

print_done:
    pop {r1, r2, r7}   @ Restaurar registros
    bx lr

grabar_ranking:
    @ Abrir/crear el archivo de ranking
    ldr r0, =ranking_filename
    mov r1, #577       @ O_WRONLY | O_CREAT | O_TRUNC
    mov r2, #0644      @ Permisos rw-r--r--
    mov r7, #5         @ sys_open
    svc #0
    mov r4, r0         @ Guardar el file descriptor

    @ Escribir el ranking
    ldr r0, =ranking_buffer
    mov r1, r4          @ file descriptor
    bl calcular_ranking_size
    mov r2, r0          @ tamaño del ranking
    mov r7, #4          @ sys_write
    svc #0

    @ Cerrar el archivo
    mov r0, r4          @ file descriptor
    mov r7, #6          @ sys_close
    svc #0
    bx lr

calcular_ranking_size:
    @ Calcular el tamaño del buffer de ranking
    push {r1, r2}
    mov r1, r0
    mov r2, #0
calcular_size_loop:
    ldrb r3, [r1], #1
    cmp r3, #0
    beq size_done
    adds r2, r2, #1
    b calcular_size_loop

size_done:
    mov r0, r2
    pop {r1, r2}
    bx lr
