.include "so.h"
.include "stack.h"
.include "delay.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000

#-- Direccion de los displays de 7 segmentos
.equ DISPLAY, 0x20c000

#-- Constantes para sacar los digitos en el display


.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- gp -> Direccion de los leds
    li gp, LEDS

    #-- s0 -> Dirección de los displays de 7 segmentos
    li s0, DISPLAY

    #-- Contador BCD de 2 digitos
    li s1, 0x99

    #-- Test
    li t0, 0xaa

loop:
    
    #-- Incrementar contador BCD
    mv a0, s1
    jal inc_bcd2
    mv s1, a0

    #-- Convertir de BCD a 7 segmentos
    jal bcd2seg

    #-- Mostrar digitos bcd en display
    sw a0, (s0)

    #-- Esperar
    DELAY100ms

    #-- Repetir
    j loop


#------------------------------------------------------------
#-- inc_bcd2
#--
#--  Incrementar el contador bcd de 2 digitos
#--
#--  ENTRADAS:
#--    -a0: Contador bcd
#--
#--  SALIDAS:
#--    -a0: Contador bcd incrementado
#------------------------------------------------------------
inc_bcd2:

    #-- Obtener bcd 0
    and t0, a0, 0x0F

    #-- Obtener bcd 1
    and t1, a0, 0xF0
    srli t1, t1, 4

    #---- Incrementar bcd 0
    addi t0, t0, 1

    #--- Comprobar si hemos llegado a 10
    li t2, 10
    blt t0, t2, inc_bcd2_end

    #--- Digito 0 vuelve a 0
    mv t0, zero

    #---- Incrementar bcd 1
    addi t1, t1, 1

    #-- Comprobar si ha llegado a 10
    blt t1, t2, inc_bcd2_end

    #-- Digito 1 vuelve a 0
    mv t1, zero

inc_bcd2_end:
    #-- Mergear los dos digitos bcd
    slli t1, t1, 4
    or a0, t1, t0
    ret

#-------------------------------------------------------------------------
#-- bcd2seg: Convertir un numero bcd de 2 digitos a su representacion
#-- en un display de 7 segmetnos
#--
#-- Entradas:
#--   a0: 2 Digitos BCD
#--
#-- Salida:
#--   a0: Salida para el display
#-------------------------------------------------------------------------
    #-- Tabla de conversion BCD --> 7 seg
    .data
tabla:
    .byte 0x3F  #-- Digito 0
    .byte 0x06  #-- Digito 1
    .byte 0x5B  #-- Digito 2
    .byte 0x4F  #-- Digito 3
    .byte 0x66  #-- Digito 4
    .byte 0x6D  #-- Digito 5
    .byte 0x7D  #-- Digito 6
    .byte 0x07  #-- Digito 7
    .byte 0x7F  #-- Digito 8
    .byte 0x6F  #-- Digito 9

    .text
bcd2seg:

    #-- Direccion base de la tabla
    la t0, tabla

    #-- a1: Digito BCD 1
    andi a1, a0, 0xF0  #-- Obtener bcd 1
    srli a1, a1, 4

    #-- a0: Digito BCD 0
    andi a0, a0, 0xF

    #-- Codificar digito 0
    add t1, t0, a0
    lb a0, 0(t1)

    #-- Codificar digito 1
    add t1, t0, a1
    lb a1, 0(t1)

    #-- Combinar a1 y a0
    slli a1, a1, 8
    or a0, a1, a0

    ret



#----- Dependencias
.include "delay.s"

