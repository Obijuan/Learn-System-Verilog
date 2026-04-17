#-- Punto de entrada del programa de prueba
.global __reset
__reset:

    #-- Operaciones sin riesgo de datos
    #-- Solo se pueden usar valores inmediatos
    #-- porque todos los registros valen 0 (no hay etapa de writeback)
                       #-- Res
    addi x10, x0, 0x10 #-- 0x10
    addi x11, x0, 0x11 #-- 0x11
    addi x12, x0, 0x12 #-- 0x12

    addi x1, x0, 1     #-- 1
    addi x2, x0, 2     #-- 2
    addi x3, x0, 3     #-- 3
    addi x4, x0, -1    #-- 0xFF
    addi x0, x0, 0

    #-- Operaciones con riegos
    #-- El registro rs1 se encuentra disponible en la fase de
    #-- ejecucion y se lleva a la anterior mediante forwarding
    addi x1, x0, 1    #-- 1
    addi x2, x1, 2    #-- 3

    addi x3, x0, 1    #-- 1
    slli x4, x3, 1    #-- 2
    slli x5, x4, 1    #-- 0x4
    slli x6, x5, 1    #-- 0x8
    slli x7, x6, 1    #-- 0x10


inf: j inf
