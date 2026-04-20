.include "so.h"
.include "delay.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000


.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    # -- Valor a escribir en mscratch	
	li t0, 0xAA
	
	#-- Ejecucion de la transaccion atomica
	csrrw t1, mscratch, t0

    #-- Ahora t1 = 0 (que es lo que tenia mscratch inicialmente)
	
	#-- Ahora volvemos a leer, en t2, y 
	#-- escribimos el valor 00 usando el registro zero (x0)
	
	csrrw t2, mscratch, zero

    #-- t2 = 0xAA

    #--- Mostrar alternativamente en los leds los valores de t1 y t2

loop:
    #-- Mostrar t1 en los leds
    sb t1, (gp)

    li a0, _1s  #-- Esperar 1 segundo
    jal delay

    #-- Mostrar t2 en los leds
    sb t2, (gp)
    li a0, _1s  #-- Esperar 1 segundo
    jal delay

    #-- Repetir
    j loop

#-- Dependencias
.include "delay.s"

