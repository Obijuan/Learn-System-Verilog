
#-- Direccion de los LEDs
.equ LEDS, 0x200000

.global __reset
__reset:

    #-- s0: Direccion de los LEDs
    li s0, LEDS

    #-- Encender led
    li t0, 1
    sw t0, (s0)

inf: j inf
