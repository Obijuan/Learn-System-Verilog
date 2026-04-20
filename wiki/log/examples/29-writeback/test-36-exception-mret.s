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
	
    #-- Secuencia final... hemos retornado de la excepcion
	LEDSI 0xFF

	halt
	
#------------------------------------------
#-- Rutina de atencion a la interrupcion
#------------------------------------------
servicio:

    #-- Encender el led0
	li t0, 3
    sb t0, 0(gp)

    #-- Esperar un segundo
    DELAY1S

    #-- mepc apunta a la instruccion que genero la excepcion
    csrr t0, mepc

    #-- Apuntar a la siguiente instruccion a la que genero la excepcion
    addi t0, t0, 4

    #-- Guardar valor en mepc
    csrw mepc, t0

    #-- Retornar
    mret

#-- Dependencias
.include "delay.s"

