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

.macro DELAY1S
    li a0, _1s
    jal delay
.endm

.macro DELAY100ms
    li a0, _100ms
    jal delay
.endm
