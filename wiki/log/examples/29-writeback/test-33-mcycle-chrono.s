.include "so.h"
.include "delay.h"
.include "leds.h"

.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- Leer ciclos iniciales
    csrr t0, mcycle

    #-- Realizar un bucle
	li a0, 10
wait:
	addi a0, a0, -1
	bgt a0, zero, wait
	
	#-- Leer ciclos finales
	csrr t1, mcycle

    #-- Calcular ciclos transcurridos
    sub t2, t1, t0
	
	#-- Mostrar valor en los leds
    sb t2, 0(gp)

    halt

#-- Dependencias
.include "delay.s"

