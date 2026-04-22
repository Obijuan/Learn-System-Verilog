.include "so.h"

#-- Direccion de los displays de 7 segmentos
.equ DISPLAY, 0x20c000

#-- Constantes para sacar los digitos en el display
.equ CERO,   0x3F
.equ UNO,    0x06
.equ DOS,    0x5B
.equ TRES,   0x4F
.equ CUATRO, 0x66
.equ CINCO,  0x6D
.equ SEIS,   0x7D
.equ SIETE,  0x07
.equ OCHO,   0x7F
.equ NUEVE,  0x6F

.global __reset
__reset:

    #-- s0 -> Dirección de los displays de 7 segmentos
    li s0, DISPLAY

    #-- Enviar digitos a los displays
    li t0, TRES  #-- Digito para el display derecho
    li t1, SIETE  #-- Digito para el display izquierda

    #-- Colocar en el byte de mayor peso
    slli t1, t1, 8

    #-- Construir media palabra con los 2 digitos a enviar
    add t0, t0, t1

    #-- Mostrar digitos en los displays
    sw t0, (s0)

    halt



