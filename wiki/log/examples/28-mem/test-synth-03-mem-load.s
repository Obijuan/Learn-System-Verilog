#-- Punto de entrada del programa de prueba
.global __reset
__reset:

    #-- Pruebas de load
    #-- Se lee el valor de la direccion 0x4_0000 (que es la
    #-- primera instrucción)
    #-- El objetivo es confirmar que la etapa mem lee correctamente
    #-- de la memoria
                       #-- Res
    lui x1, 0x40       #-- x1 = 0x4_0000
    lw x2, 0(x1)       #-- x2 = 000400b7


inf: j inf
