.include "so.h"
.include "stack.h"
.include "delay.h"
.include "assert.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000


.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- s0 -> Direccion de los leds
    li gp, LEDS

    #-- Prueba de assert
    #-- Si falla se muestra 1 en los leds (numero de test fallado)
    li t0, 0xAA
    ASSERT_EQUAL t0, 0xAA, 1


    li t0, 1
    ASSERT_EQUAL t0, 1, 2

    li t2, 3
    li t5, 3
    assert_value t5, 11





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
.include "assert.s"
.include "delay.s"
.include "seq.s"

   .align 4
var:
    .word 0xcafebabe
