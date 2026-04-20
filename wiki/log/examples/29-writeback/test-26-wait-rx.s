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
.equ RX_FULL,  0x00040000

.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- tp -> Direccion de la UART
    li tp, UART

    #-- s0: Contador de caracteres recibidos
    li s0, 1

 wait_rx:
	#-- Leer el registro de estado del receptor
	lw t0, (tp)
	
	#-- Aislar el bit RX_FULL
    li t1, RX_FULL
	and t0, t0, t1
	
	#-- Si el bit es 0, no se ha recibido ningun caracter
	#-- (el receptor NO está listo)
	#-- repetimos la accion hasta que se ponga a 1
	beq t0, zero, wait_rx
    
    #-- Incrementar contador de caracteres recibidos
    addi s0, s0, 1

    #-- Mostrar el contador en los leds
    sw s0, (gp)

    j wait_rx





