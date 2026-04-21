.include "so.h"
.include "stack.h"
.include "delay.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000


.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- Bucle principal
 main_loop:
    #-- Encender el LED 0
    li t0, 0x01
    sw t0, (gp)

    #-- Esperar
    DELAY250ms

    #-- Apagar led
    sw zero, (gp)

    #-- Esperar
    DELAY250ms 

    #-- Repetir
    j main_loop


#----- Dependencias
.include "delay.s"



