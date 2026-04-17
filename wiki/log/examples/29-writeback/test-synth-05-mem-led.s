.global __reset
__reset:

    #-- Escritura en los LEDs
    #-- Estan en la direccion 0x20_0000  (que es la 0x8_0000) de palabra
    #-- Se escribe el valor 0
    lui x1, 0x200
    sw x0, 0(x1)

inf: j inf
