.include "so.h"
.include "stack.h"
.include "delay.h"
.include "assert.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000

#-- Direccion de la UART
.equ UART, 0x210000

#<--------- TX STATUS ---------> <-------- RX STATUS ---------> 
#|           31...24           |||          23...16           ||
#| 31-27|   26   |  25 |  24   ||| 23-19|   18  |  17 |  16   ||
#| xxxxx|TX_EMPTY|TX_IE|TX_ERR ||| xxxxx|RX_FULL|RX_IE|RX_ERR ||

#<----------> <- BUFFER ->
#|  15...8  |||  7...0   |
#| 15-----8 ||| 7------0 |
#| xxxxxxxx |||  BUFFER  |

#-- Máscaras de acceso a los bits
#-- Bit Ready del transmisor
.equ TX_EMPTY, 0x04000000  

.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- tp -> Direccion de la UART
    li tp, UART

    #-- Imprimir una cadena
	la a0, msg1
	jal puts

    #-- Imprimir otra cadena
    la a0, msg2
    jal puts
    

#------------------------------------
#-- TESTs pasado con exito
#------------------------------------

    #-- Mostrar una secuencia
    li a0, 0x5555AAAA  #-- Secuencia
    li a1, _100ms      #-- Pausa
    li a2, 20           #-- Repeticiones
    jal play_seq

    #-- Terminar con todos los leds encendidos
    li t0, 0xFF
    sw t0, (gp)

    #-- STOP
    halt




#----- Dependencias
.include "io-uart.s"
.include "stdio.s"
.include "assert.s"
.include "delay.s"
.include "seq.s"


    .data
msg1:  .string "Hola Mundo!\n"
msg2:  .string "Test...\n"

