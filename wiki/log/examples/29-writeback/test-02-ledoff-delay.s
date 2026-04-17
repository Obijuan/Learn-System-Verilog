
#-- Direccion de los LEDs
.equ LEDS, 0x200000

#-- Valores para las pausas
.equ _200ms, 0xC3500
.equ _250ms, 0xF4240
.equ _500ms, _250ms * 2
.equ _1s, _250ms * 4

.global __reset
__reset:

    #-- s0: Direccion de los LEDs
    li s0, LEDS

    #-- Encender led
    li t0, 1
    sw t0, (s0)

    #-- Realizar una pausa
    li t1, _1s
loop:
    beq t1,zero, cont
    addi t1, t1, -1
    j loop


    #-- Apagar LED
cont:
    sw zero, (s0)

    #-- STOP!
inf: j inf
