.include "so.h"
.include "stack.h"
.include "delay.h"
.include "io-uart.h"
.include "stdio.h"

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

    #-- s0: Estado del LED0
    li s0, 1

    #-- Encender el LED0
    sb s0, (gp)

    PUTSI "Haciendo eco:\n"

    #--- Configuracion de la rutina de atencion
	#--- a la interrupcion
	la t0, servicio
	csrw mtvec, t0

    #-- Habilitar las interrupciones del receptor de la UART
    li t0, RX_IE
    sb t0, UART_RXSTATUS(tp)

    #-- Habilitar las interrupciones externas
    li t0, MIE_MEIE_MASK
    csrs mie, t0

    #-- Habilitar las interrupciones a nivel global
    li t0, MSTATUS_MIE_MASK
    csrs mstatus, t0

 loop:
 
	#-- Esperar
    DELAY250ms

    #-- Apagar led
    sb zero, (gp)

    #-- Esperar
    DELAY250ms

    #-- Encender led
    sb s0, (gp)

    #-- repetir
    j loop

#------------------------------------------
#-- Rutina de atencion a la interrupcion
#------------------------------------------
servicio:
    #-- Crear pila
    addi sp, sp, -16

    #-- Guardar registros usados
    sw ra, 0(sp)
    sw a0, 4(sp)

    #-- Leer el dato recibido
    #-- Esto borra el flag de interrupcion
    lb a0, UART_DATA(tp)

    #-- Hacer eco
    jal putchar

    #-- Recueparar registros
    sw a0, 4(sp)
    lw ra, 0(sp)

    #-- Liberar la pila
    addi sp, sp, 16

    #-- retornar
    mret



#--- Dependencias
.include "delay.s"
.include "io-uart.s"
.include "stdio.s"

	.data
menu:	.ascii "----MENU-----\n"
        .ascii "1.- Mostrar el menu\n"
        .ascii "2.- Cambiar estado del LED0\n"
        .ascii "q.- Quit\n"
	    .ascii "\nOpcion?: "
	    .byte 0
	
msg_end: .string "\nFin\n"
msg_test: .string "\nProbando la opcion 2...\n\n"
	
