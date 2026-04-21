.include "so.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000


.global __reset
__reset:

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- Encender el LED 0
    li t0, 0x01
    sw t0, (gp)

    halt



