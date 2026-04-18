#-------------------------------------------------
#-- Subrutina para reproduccion de secuencias
#-- Entradas:
#--   a0: Secuencia de 4 bytes a mostrar
#--   a1: Pausa entre bytes de la secuencia
#--   a2: Numero de iteraciones a realizar
#-------------------------------------------------
play_seq:
    STACK16

    #-- Almacenar secuencia en la pila
    sw a0, 0(sp)

    #-- Almacenar tiempo en la pila
    sw a1, 4(sp)

    #-- Almacenar num iteraciones en la pila
    sw a2, 8(sp)

 next:
    #-- Mostrar byte 0 en los leds
    lw t0, (sp)
    sw t0, (gp)
    lw a0, 4(sp)
    jal delay

    #-- Mostrar byte 1 en los leds
    lw t0, (sp)
    srli t0, t0, 8
    sw t0, (gp)
    lw a0, 4(sp)
    jal delay

    #-- Mostrar byte 2 en los leds
    lw t0, (sp)
    srli t0, t0, 16
    sw t0, (gp)
    lw a0, 4(sp)
    jal delay

    #-- Mostrar byte 3 en los leds
    lw t0, (sp)
    srli t0, t0, 24
    sw t0, (gp)
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

    UNSTACK16
    