.include "so.h"
.include "stack.h"
.include "delay.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000


.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- s0 -> Direccion de los leds
    li s0, LEDS

    li a0, 0x5555AAAA  #-- Secuencia
    li a1, _100ms      #-- Pausa
    li a2, 3           #-- Repeticiones
    jal play_seq

    li t0, 0xFF
    sw t0, (s0)

    #-- STOP
    halt


#----- Dependencias
.include "delay.s"
.include "seq.s"


