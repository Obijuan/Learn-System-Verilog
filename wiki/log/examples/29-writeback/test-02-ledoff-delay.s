
#-- Direccion de los LEDs
.equ LEDS, 0x200000

.global __reset
__reset:

    #-- s0: Direccion de los LEDs
    li s0, LEDS

    #-- Encender led
    li t0, 1
    sw t0, (s0)

    #-- Realizar una pausa
    li t1, 0xFFFFF
loop:
    beq t1,zero, cont
    addi t1, t1, -1
    j loop


    #-- Apagar LED
cont:
    sw zero, (s0)

    #-- STOP!
inf: j inf
