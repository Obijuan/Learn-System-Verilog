.include "so.h"
.include "timer.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000

.global __reset
__reset:

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- Direccion basel del timer
    li s0, TIMER

 loop:
    #-- Leer temporizador
    lw t0, MTIME(s0)

    #-- Eliminar los 18 bits de menor peso
    srli t0, t0, 18

    #-- Observar los bits del 18 al 25
    sw t0, (gp)

    #-- Repetir
    j loop




