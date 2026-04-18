.macro halt
    j .
.endm


#-- Direccion de los LEDs
.equ LEDS, 0x200000

.global __reset
__reset:

   #-- x1 -> Direccion de los leds
   li x1, LEDS

   #-- x2 -> Direccion de la variable
   la x2, var

   #-- Escribir valor en variable
   li x3, 0x01
   xori x0, x0, 0
   ori x0, x0, 0
   andi x0, x0, 0
   sw x3, (x2)

   xori x0, x0, 0
   ori x0, x0, 0
   andi x0, x0, 0

   #-- Leer variable
   lw x4, (x2)  

   #-- Mostrar variable en los leds
   sw x4, (x1)

   #-- STOP
   halt

   .align 4
var:
    .word 0xFF

