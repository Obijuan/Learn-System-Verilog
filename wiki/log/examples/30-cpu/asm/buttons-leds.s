.include "so.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000

#-- Direccion de los pulsadores
.equ BUTTONS,0x204000

.global __reset
__reset:

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- s0 -> Direccion de los pulsadores
    li s0, BUTTONS

    #-- Bucle principal
 loop:

    #-- Leer los pulsadores
    lb t0, (s0)

    #-- Enviar estado pulsadores a los leds
    sb t0, (gp)

    #-- Repetir
    j loop

    halt



