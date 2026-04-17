
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

#----------------------------
#-- LED PARPADEANTE
#----------------------------
#-- Pausa a realizar
.equ PAUSA, _100ms

.global __reset
__reset:

    #-- s0: Direccion de los LEDs
    li s0, LEDS

loop:
    #-- Encender led
    li t0, 1
    sw t0, (s0)

    #-- Pausa
    li a0, PAUSA
    jal delay

    #-- Apagar led
    sw zero, (s0)

    #-- Pausa de 1seg
    li a0, PAUSA
    jal delay

    j loop

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
