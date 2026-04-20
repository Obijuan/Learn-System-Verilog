.include "so.h"
.include "delay.h"
.include "leds.h"

.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

   	#--- Configuracion de la rutina de atencion
	#--- a la interrupcion
	la t0, servicio
	csrw mtvec, t0
			
	#-- Generamos una excepcion
	#-- El programa salta a ejecutar servicio
	lw zero, 1(zero)
	
    #-- Los leds NUNCA se encienden...
	LEDSI 0xFF

	halt
	
#------------------------------------------
#-- Rutina de atencion a la interrupcion
#------------------------------------------
servicio:

    #-- Encender el led0
	li t0, 1
    sb t0, 0(gp)

    #-- Nunca terminar
    halt

#-- Dependencias
.include "delay.s"

