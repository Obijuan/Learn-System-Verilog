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

    #-- Determinar la causa de la trap
    #-- 1o: Leer la causa de la trap
    csrr t0, mcause

    #-- Si bit 31 es 1, es una interrupcion. 
    #-- Si bit 31 es 0, es una excepcion
    blt t0, zero, servicio_interrupt

    #-- Es una excepcion!!!
    #-- NO guardamos s0 en pila porque nunca se retorna...
    mv s0, t0
    
    #-- Mostrar la causa en los leds
    sb s0, 0(gp)

loop:
    #-- Hacemos parpadear el led de mayor peso para indicar que 
    #-- ha ocurrido una excepcion
    DELAY100ms

    #-- Cambiar de estado el bit de mayor peso
    xori s0, s0, 0x80
    sb s0, 0(gp)  #-- LEDs!

    #-- Repetir....
    j loop


#--------------------------------------------
#-- Rutina de atencion a las interrupciones
#--------------------------------------------
servicio_interrupt:

    #-- Mostrar la causa en los leds
    sb t0, 0(gp)

    halt


#-- Dependencias
.include "delay.s"

