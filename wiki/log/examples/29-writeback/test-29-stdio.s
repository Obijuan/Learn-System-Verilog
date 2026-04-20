.include "so.h"
.include "stack.h"
.include "delay.h"
.include "assert.h"
.include "io-uart.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000


.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- tp -> Direccion de la UART
    li tp, UART_BASE


    #-- Imprimir mensaje
    la a0, msg1
    jal puts

    la a0, msg2
    jal puts
    

loop:

    #-- Esperar a que se reciba un caracter
    jal getchar

    #-- Mostrar caracter recibido en los leds
    sb a0, (gp)

    #-- Hacer eco!
    jal putchar

    j loop


#--- Dependencias
.include "io-uart.s"
.include "stdio.s"

.data
msg1: .string "OK!\n"
msg2: .string "Test...\n"
