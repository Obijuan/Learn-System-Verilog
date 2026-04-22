.include "so.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000

#-- Direccion de los switches
.equ SWITCHES, 0x208000


.global __reset
__reset:

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- s0 -> Direccion de los switches
    li s0, SWITCHES

    #-- Bucle principal
 loop:

    #-- Leer los switches
    lb t0, (s0)

    #-- Enviar estado switches a los leds
    sb t0, (gp)

    #-- Repetir
    j loop

    halt



