
#-- Direccion de los LEDs
.equ LEDS, 0x200000

.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40400

    #-- s0: Direccion de los LEDs
    li s0, LEDS

    #-- LEDs = 1
    li t0, 1
    sw t0, (s0)

    #-- Llamar al nivel 1
    jal nivel1

    #-- Imprmir valor final
    li t0, 0x1F
    sw t0, (s0)

inf:    j inf


 nivel1:
    addi sp, sp, -16
    sw ra, 12(sp)

    li t0, 3
    sw t0, (s0)

    jal nivel2

    li t0, 0x0F
    sw t0, (s0)

    lw ra, 12(sp)
    addi sp, sp, 16
    ret

 nivel2:
    li t0, 7
    sw t0, (s0)
    ret

