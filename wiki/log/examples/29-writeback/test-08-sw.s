.macro halt
    j .
.endm


#-- Direccion de los LEDs
.equ LEDS, 0x200000

.global __reset
__reset:

   #-- S0 -> Direccion de los leds
   li s0, LEDS

   #-- S1 -> Direccion de la variable
   la s1, var

   #-- Escribir valor en variable
   li t0, 0x01
   sw t0, (s1)

   #-- Leer variable
   lw t1, (s1)  

   #-- Mostrar variable en los leds
   sw t1, (s0)

   #-- STOP
   halt

   .align 4
var:
    .word 0xFF

