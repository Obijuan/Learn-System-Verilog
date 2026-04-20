.include "so.h"
.include "delay.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000


#-- Ejemplo de uso de la instruccion csrw 

.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    # -- Escribir valor en mscratch
	li t0, 0xC3
	csrw mscratch, t0

loop:
    #-- Leer valor de mscratch en t1
    csrr t1, mscratch

    #-- Mostrar valor leido en los leds
    sb t1, (gp)

    j loop

#-- Dependencias
.include "delay.s"

