#-- Punto de entrada del programa de prueba
.global __reset
__reset:

    #-- Pruebas de store
    #-- Se almacena el valor 0x40A0 en la direccion 0x40A0
                       #-- Res
    lui x1, 0x40       #-- x1 = 0x4_0000
    addi x2, x1, 0xA0  #-- x2 = 0x4_00A0
    sw x2, 0(x2)       #-- x2 = 000400b7

    nop
    nop

    lui x1, 0x40       #-- x1 = 0x4_0000
    addi x2, x1, 0xA0  #-- x2 = 0x4_00A0
    lw x3, 0(x2)       #-- x3 = 0x4_00A0


inf: j inf
