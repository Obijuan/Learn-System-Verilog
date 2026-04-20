.include "so.h"
.include "delay.h"
.include "leds.h"

.global __reset
__reset:

    # -- Leer los ciclos iniciales en t0
	#-- (0 ciclos)
	csrr t0, mcycle
    nop
    csrr t1, mcycle
    nop
    csrr t2, mcycle

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

loop:
    #-- Mostrar ciclos en los leds
    LEDSR t0
    DELAY1S

    LEDSR t1
    DELAY1S

    LEDSR t2
    DELAY1S

    j loop


    halt

#-- Dependencias
.include "delay.s"

