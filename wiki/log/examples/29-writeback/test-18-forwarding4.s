.include "so.h"
.include "stack.h"
.include "delay.h"
.include "assert.h"

#-- Direccion de los LEDs
.equ LEDS, 0x200000


.global __reset
__reset:

    #-- Inicializar la pila
    li sp, 0x40800

    #-- s0 -> Direccion de los leds
    li gp, LEDS

    #-- Prueba de assert
    #-- Si falla se muestra 1 en los leds (numero de test fallado)
    li t0, 0xAA
    ASSERT_EQUAL t0, 0xAA, 1


#----- Init....
    la t4, var
    li t1, 1

# -------------------------------
# Override destination register
# exe - mem
addi t2, zero, 46
addi t5, zero, 0x33
sw t5, 0(t4)
flush_pipeline
# ----------------------
lw t6, 0(t4)           #
addi t6, zero, 0x44    #
add s0, t6, t6         #
#-----------------------
flush_pipeline
assert_value s0, 0x88

# -------------------------------
# Override destination register
# exe - mem
addi t2, zero, 47
addi t5, zero, 0x33
sw t5, 0(t4)
flush_pipeline
# ----------------------
lw t6, 0(t4)           #
addi t6, zero, 0x80    #
add t6, t6, t6         #
#-----------------------
flush_pipeline
assert_value t6, 0x100


# -------------------------------
# Override destination register
# exe - mem
addi t2, zero, 48
addi t5, zero, 0x2
sw t5, 0(t4)
flush_pipeline
# ----------------------
addi t6, zero, 0x1     #
lw t6, 0(t4)           #
add s0, t6, zero       #
#-----------------------
flush_pipeline
assert_value s0, 0x2

# -------------------------------
# Override destination register
# exe - mem
addi t2, zero, 49
addi t5, zero, 0x22
sw t5, 0(t4)
flush_pipeline
# ----------------------
addi t6, zero, 0x11    #
lw t6, 0(t4)           #
add s0, zero, t6       #
#-----------------------
flush_pipeline
assert_value s0, 0x22

# -------------------------------
# Override destination register
# exe - mem
addi t2, zero, 50
addi t5, zero, 0x222
sw t5, 0(t4)
flush_pipeline
# ----------------------
addi t6, zero, 0x111   #
lw t6, 0(t4)           #
add s0, t6, t6         #
#-----------------------
flush_pipeline
assert_value s0, 0x444

# -------------------------------
# Override destination register
# exe - mem
addi t2, zero, 51
addi t5, zero, 0x100
sw t5, 0(t4)
flush_pipeline
# ----------------------
addi t6, zero, 0x555   #
lw t6, 0(t4)           #
add t6, t6, t6         #
#-----------------------
flush_pipeline
assert_value t6, 0x200





#------------------------------------
#-- TESTs pasado con exito
#------------------------------------

    #-- Mostrar una secuencia
    li a0, 0x5555AAAA  #-- Secuencia
    li a1, _100ms      #-- Pausa
    li a2, 20           #-- Repeticiones
    jal play_seq

    #-- Terminar con todos los leds encendidos
    li t0, 0xFF
    sw t0, (gp)

    #-- STOP
    halt


#----- Dependencias
.include "assert.s"
.include "delay.s"
.include "seq.s"

   .align 4
var:
    .word 0xcafebabe
