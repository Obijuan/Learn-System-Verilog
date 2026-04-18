.macro halt
    j .
.endm


#-- Direccion de los LEDs
.equ LEDS, 0x200000

#-- Valores para las pausas
#-- Valores magicos calculados a partir de esta ecuacion
#--  Tiempo = ( CiclosPorIteracion ∗ Iteraciones ) / 12 Mhz
#-- La rutina usada tarda 3 ciclos por iteracción y tiene N iteraciones
#-- Tiempo = (3 * N)/12 Mhz --> N = (12_000_000*Tiempo)/3 
.equ _100ms, 0x61a80
.equ _200ms, _100ms * 2
.equ _250ms, 0xF4240
.equ _500ms, _250ms * 2
.equ _1s, _250ms * 4

#-- Pausa a realizar
.equ PAUSA, _1s


.global __reset
__reset:

   #-- S0 -> Direccion de los leds
   li s0, LEDS

 loop:
   #-- Leer variable
   la s1, var
   lw t0, (s1)  

   #-- Enviar byte bajo de la variable a los leds
   sw t0, (s0)

   #-- Pausa
   li a0, PAUSA
   jal delay

   #-- Obtener el siguiente byte
   srli t0, t0, 8
   sw t0, (s0)

   #-- Pausa
   li a0, PAUSA
   jal delay

   #-- Mostrar byte 3
   srli t0, t0, 8
   sw t0, (s0)

   #-- Pausa
   li a0, PAUSA
   jal delay

   #-- Mostrar byte 4
   srli t0, t0, 8
   sw t0, (s0)

   #-- Pausa
   li a0, PAUSA
   jal delay

   #-- Repetir
   j loop

   #-- STOP
   halt

#--------------------------
#-- Subrutina de delay
#-- Espera de 1seg
#--------------------------
delay:

    #-- Loop
 1:
    beq a0,zero, 2f
    addi a0, a0, -1
    j 1b

    #-- Condicion de salida
 2:
    ret



   .align 4
var:
    .word 0xAA55FF01

