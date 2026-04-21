.include "so.h"
.include "timer.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000

#-- Direccion de los pulsadores
.equ BUTTONS,0x204000

.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- Direccion base del timer
    li s0, TIMER

    #-- s1 -> Direccion de los pulsadores
    li s1, BUTTONS

    #--- Configuracion de la rutina de atencion
	#--- a la interrupcion
	la t0, servicio
	csrw mtvec, t0

    #-- Leer el temporizador
    lw t0, MTIME(s0)

    #-- Incrementarlo en 100ms
    li t1, 1200000  #-- 1200000 ciclos -> 100ms
    add t0, t0, t1  #-- t0 = counter + 100ms

    #-- Escribir en el comparador
    sw t0, MTIMECMP(s0)

    #-- Activar las interrupciones
    #-- En 1ms debería producirse una!
    #-- Habilitar la interrupcion del temporizador
    li t0, MIE_MTIE_MASK
    csrs mie, t0

    #-- Habilitar las interrupciones a nivel global
    li t0, MSTATUS_MIE_MASK
    csrs mstatus, t0

    #-- s2: Contador de decimas de segundo
    li s2, 0


    #--- Bucle principal. Mostrar los pulsadores en los 2 bits
    #-- de mayor peso de los LEDs
 loop:
    #-- Leer los pulsadores
    lb t0, (s1)

    #-- Desplazarlo a los 2 bits de mayor peso
    slli s3, t0, 6

    j loop


#------------------------------------------
#-- Rutina de atencion a la interrupcion
#------------------------------------------
servicio:

    #-- Crear la pila
    addi sp, sp, -16

    #-- Almacenar los registros usados
    sw t0, 0(sp)
    sw t1, 4(sp)

    #-- Incrementar contador de decimas de segundo
    addi s2, s2, 1

    #-- Truncar el contador a 6 bits
    andi s2, s2, 0x3F

    #-- Mostrar el contador en los leds
    #-- Junto con la secuencia manual
    or s2, s2, s3
    sb s2, (gp)

    #-- Leer el temporizador
    lw t0, MTIME(s0)

    #-- Incrementarlo en 1ms
    li t1, 1200000  #-- 1200000 ciclos -> 100ms
    add t0, t0, t1  #-- t0 = counter + 100ms

    #-- Escribir en el comparador
    sw t0, MTIMECMP(s0)

    #-- Recuperar registros usados
    lw t0, 0(sp)
    lw t1, 4(sp)

    #-- Liberar la pila
    addi sp, sp, 16

    mret

