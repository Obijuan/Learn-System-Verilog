.include "so.h"
.include "stack.h"
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

 loop:
    #-- Imprimir el menu
	la a0, menu
	jal puts

 wait_user:
	#-- Esperar a que se pulse una tecla
	jal getchar

	#-- Saltar a la opcion correspondiente
	li t0, '1'
	beq a0, t0, opcion1
	
	li t0, '2'
	beq a0, t0, opcion2
	
	li t0, 'q'
	beq a0, t0, fin
	
	#-- Opcion incorrecta, volver a pedir otra
	j wait_user


	#-- Opcion 1: volver a imprimir el menu
opcion1:
    li a0, '\n'
	jal putchar
	
	li a0, '\n'
	jal putchar
	
	j loop
	
	#-- Opcion 2: Cambiar el estado del LED0
opcion2:
    PUTSI "LED0!\n"

    #-- Cambiar de estado LED0
    xor s0, s0, 1
    sb s0, (gp)

	j wait_user

	#-- Terminar
fin: 	
	PUTSI "Fin!!\n"
    halt


#--- Dependencias
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
	
