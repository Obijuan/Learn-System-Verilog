.macro halt
    j .
.endm


#-- Direccion de los LEDs
.equ LEDS, 0x200000

.global __reset
__reset:

   #-- S0 -> Direccion de los leds
   li s0, LEDS

   #-- Leer variable
   la s1, var
   lw t0, (s1)  

   #-- Enviar variable a los leds
   sw t0, (s0)

   #-- STOP
   halt



   .align 4
var:
    .word 0xC3

