.include "so.h"
.include "delay.h"
.include "leds.h"

.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- Generamos una excepcion
	#-- Lectura de lectura NO alineada
	#-- Runtime exception at 0x00400000: 
	#-- Load address not aligned to word boundary 0x00000001
	lw zero, 1(zero)
	
    #-- Los leds NUNCA se encienden...
	LEDSI 0xFF

    halt

#-- Dependencias
.include "delay.s"

