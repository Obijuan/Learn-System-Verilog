.include "so.h"
.include "stack.h"
.include "delay.h"
.include "assert.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000

#-- Direccion base de la UART
.equ UART_BASE, 0x210000

#-- Offset de los registros de la UART
.equ UART_DATA, 0x0
.equ UART_RXSTATUS, 0x2
.equ UART_TXSTATUS, 0x3

#-- Registro de status del receptor
#<-------- RX STATUS ---------> 
#|          23...16           ||
#| 23-19|   18  |  17 |  16   ||
#| xxxxx|RX_FULL|RX_IE|RX_ERR ||
.equ RX_FULL, 0x4
.equ RX_IE, 0x2
.equ RX_ERR, 0x1

#-- Registro de status del transmisor
#<--------- TX STATUS ---------> 
#|           31...24           ||
#| 31-27|   26   |  25 |  24   ||
#| xxxxx|TX_EMPTY|TX_IE|TX_ERR ||
.equ TX_EMPTY, 0x40
.equ TX_IE, 0x20
.equ TX_ERR, 0x10


.global __reset
__reset:

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- tp -> Direccion de la UART
    li tp, UART_BASE

 wait_rx:
	#-- Leer el registro de estado del receptor
	lb t0, UART_RXSTATUS(tp)
	
	#-- Aislar el bit RX_FULL
	andi t0, t0, RX_FULL
	
	#-- Si el bit es 0, no se ha recibido ningun caracter
	#-- (el receptor NO está listo)
	#-- repetimos la accion hasta que se ponga a 1
	beq t0, zero, wait_rx
    
    #-- Leer el caracter recibido
    lb t1, UART_DATA(tp)

    #-- Mostrar caracter recibido en los leds
    sw t1, (gp)

    j wait_rx





