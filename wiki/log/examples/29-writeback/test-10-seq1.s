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

   #-- Inicializar la pila
   li sp, 0x40800

   #-- s0 -> Direccion de los leds
   li s0, LEDS

    li a0, 0xC0300C03  #-- Secuencia
    li a1, _250ms      #-- Pausa
    li a2, 10           #-- Repeticiones
    jal play_seq

    li t0, 0xFF
    sw t0, (s0)

   #-- STOP
   halt

#-------------------------------------------------
#-- Subrutina para reproduccion de secuencias
#-- Entradas:
#--   a0: Secuencia de 4 bytes a mostrar
#--   a1: Pausa entre bytes de la secuencia
#--   a2: Numero de iteraciones a realizar
#-------------------------------------------------
play_seq:
    #-- Crear pila
    addi sp, sp, -16

    #-- Guardar direccion de retorno
    sw ra, 12(sp)

    #-- Almacenar secuencia en la pila
    sw a0, 0(sp)

    #-- Almacenar tiempo en la pila
    sw a1, 4(sp)

    #-- Almacenar num iteraciones en la pila
    sw a2, 8(sp)

 next:
    #-- Mostrar byte 0 en los leds
    lw t0, (sp)
    sw t0, (s0)
    lw a0, 4(sp)
    jal delay

    #-- Mostrar byte 1 en los leds
    lw t0, (sp)
    srli t0, t0, 8
    sw t0, (s0)
    lw a0, 4(sp)
    jal delay

    #-- Mostrar byte 2 en los leds
    lw t0, (sp)
    srli t0, t0, 16
    sw t0, (s0)
    lw a0, 4(sp)
    jal delay

    #-- Mostrar byte 3 en los leds
    lw t0, (sp)
    srli t0, t0, 24
    sw t0, (s0)
    lw a0, 4(sp)
    jal delay

    #-- Recuperar las iteracciones
    lw t0, 8(sp)

    #-- Una menos
    addi t0, t0, -1
    sw t0, 8(sp)

    #-- Comprobar terminacion
    bgt t0, zero, next

    #--- Fin!

    #-- Recuperar direccion de retorno
    lw ra, 12(sp)

    #-- Liberar pila
    addi sp, sp, 16
    ret


#--------------------------
#-- Subrutina de delay
#-- Espera de 1seg
#-- Entradas:
#--   a0: Pausa
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
