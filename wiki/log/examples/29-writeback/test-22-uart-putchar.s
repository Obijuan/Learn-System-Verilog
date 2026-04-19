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


    #------- Envio del primer caracter
	li a0, 'A'
    jal putchar

    #-- Envio del segundo caracter
    li a0, 'B'
    jal putchar

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

#--------------------------------------------------------------
#-- uart_wait_tx_ready()
#--
#-- Esperar hasta que el bit TX_EMPTY del transmisor
#-- se ponga a 1
#--
#-- El registro tp debe contener la direccion base de la uart
#--------------------------------------------------------------
uart_wait_tx_ready:
    #-- Leer el registro de status de la UART
    lw t0, 0(tp)
    
    #-- Aislar el bit TX_EMPTY
    li t1, TX_EMPTY
    and t0, t0, t1
    
    #-- Si el bit es 0, el transmisor no esta listo
    #-- repetimos la accion hasta que se ponga a 1
    beq t0, zero, uart_wait_tx_ready

    #-- Retornar al caller
    ret


#---------------------------------------------------------------
#-- putchar(c): Imprimir un caracter
#--
#-- ENTRADA:
#--   - a0 (c): Carácter a imprimir
#--
#-- El registro tp debe contener la direccion base de la uart
#---------------------------------------------------------------
putchar:

	STACK16
	
	#-- Esperar a que el transmisor esté listo
	jal uart_wait_tx_ready
	
	#-- Escribir el caracter en el registro de datos
	sw a0, 0(tp)
	
	#-- Recuperar la dirección de retorno y liberar la pila
	UNSTACK16


#----- Dependencias
.include "assert.s"
.include "delay.s"
.include "seq.s"

