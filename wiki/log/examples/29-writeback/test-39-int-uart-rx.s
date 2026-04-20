.include "so.h"
.include "delay.h"
.include "leds.h"
.include "io-uart.h"

#--- Registro MIE: INTERRUPT ENABLE
.equ MIE_MEIE, 11  #-- Bit: Machine External Interrupt Enable
.equ MIE_MEIE_MASK, (1 << MIE_MEIE)  #-- Mascara para activa el bit

#--- Registre MSTATUS
.equ MSTATUS_MIE, 3  #-- Bit: Machine Interrupt Enable
.equ MSTATUS_MIE_MASK, (1 << MSTATUS_MIE)  #-- Mascara para activa el bit

.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- tp -> Direccion base de la UART
    li tp, UART_BASE

    #-- Valor inicial a mostrar en leds
    li t0, 0xaa
    sb t0, 0(gp)  #-- LEDs!

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

    #-- Inicializar contador de interrupciones externas
    li s0, 0

    #-- Esperar a que ocurra la interrupcion
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


#-------------------------------------------------
#-- Rutina de atencion a las excepciones
#-------------------------------------------------
servicio_excepcion:
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

    #-- Incrementar contador de interrupciones
    addi s0, s0, 1

    #-- Mostrar contador en los leds
    sb s0, 0(gp)

    #-- Leer el dato recibido
    #-- Esto borra el flag de interrupcion
    lb t0, UART_DATA(tp)

    #-- Retornar
    mret


#-- Dependencias
.include "delay.s"

