#-- Direccion de los LEDs
.equ LEDS, 0x200000

#-- Mostrar en los LEDs el valor del registro
.macro LEDSR reg:req
    sw \reg, 0(gp)
.endm

#-- Mostrar en los leds un valor inmediato
.macro LEDSI val:req
    li t0, \val
    sw t0, 0(gp)
.endm

