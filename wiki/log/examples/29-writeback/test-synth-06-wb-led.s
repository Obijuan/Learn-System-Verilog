.global __reset
__reset:

    #-- Escritura en los LEDs
    #-- Estan en la direccion 0x20_0000  (que es la 0x8_0000) de palabra
    #-- Se escribe el valor 0xAA
    lui x1, 0x200
    addi x2, x0, 0xAA
    sw x2, 0(x1)

inf: j inf
