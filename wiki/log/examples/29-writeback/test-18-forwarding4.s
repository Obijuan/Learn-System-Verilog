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

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 52
addi t5, zero, 0x1
csrw mscratch, t5
flush_pipeline
# ----------------------
csrr t6, mscratch      #
addi t6, zero, 0x2     #
add s0, t6, zero       #
#-----------------------
flush_pipeline
assert_value s0, 0x2

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 53
addi t5, zero, 0x11
csrw mscratch, t5
flush_pipeline
# ----------------------
csrr t6, mscratch      #
addi t6, zero, 0x22    #
add s0, zero, t6       #
#-----------------------
flush_pipeline
assert_value s0, 0x22

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 54
addi t5, zero, 0x111
csrw mscratch, t5
flush_pipeline
# ----------------------
csrr t6, mscratch      #
addi t6, zero, 0x222   #
add s0, t6, t6         #
#-----------------------
flush_pipeline
assert_value s0, 0x444

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 55
addi t5, zero, 0x333
csrw mscratch, t5
flush_pipeline
# ----------------------
csrr t6, mscratch      #
addi t6, zero, 0x444   #
add t6, t6, t6         #
#-----------------------
flush_pipeline
assert_value t6, 0x888

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 56
addi t5, zero, 0x1
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x2     #
csrr t6, mscratch      #
add s0, t6, zero       #
#-----------------------
flush_pipeline
assert_value s0, 0x1

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 57
addi t5, zero, 0x11
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x22    #
csrr t6, mscratch      #
add s0, zero, t6       #
#-----------------------
flush_pipeline
assert_value s0, 0x11

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 58
addi t5, zero, 0x111
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x333   #
csrr t6, mscratch      #
add s0, t6, t6         #
#-----------------------
flush_pipeline
assert_value s0, 0x222
 
# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 59
addi t5, zero, 0x100
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x444   #
csrr t6, mscratch      #
add t6, t6, t6         #
#-----------------------
flush_pipeline
assert_value t6, 0x200


# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 60
addi t5, zero, 0x1
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x2     #
csrr t6, mscratch      #
nop                    #
add s0, t6, zero       #
#-----------------------
flush_pipeline
assert_value s0, 0x1

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 61
addi t5, zero, 0x11
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x22    #
csrr t6, mscratch      #
nop                    #
add s0, zero, t6       #
#-----------------------
flush_pipeline
assert_value s0, 0x11

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 62
addi t5, zero, 0x111
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x333   #
csrr t6, mscratch      #
nop                    #
add s0, t6, t6         #
#-----------------------
flush_pipeline
assert_value s0, 0x222

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 63
addi t5, zero, 0x100
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x444   #
csrr t6, mscratch      #
nop
add t6, t6, t6         #
#-----------------------
flush_pipeline
assert_value t6, 0x200




# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 64
addi t5, zero, 0x1
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x2     #
csrr t6, mscratch      #
nop                    #
nop                    #
add s0, t6, zero       #
#-----------------------
flush_pipeline
assert_value s0, 0x1

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 65
addi t5, zero, 0x11
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x22    #
csrr t6, mscratch      #
nop                    #
nop                    #
add s0, zero, t6       #
#-----------------------
flush_pipeline
assert_value s0, 0x11

# -------------------------------
# Override destination register
# exe - wb
addi t2, zero, 66
addi t5, zero, 0x111
csrw mscratch, t5
flush_pipeline
# ----------------------
addi t6, zero, 0x333   #
csrr t6, mscratch      #
nop                    #
nop                    #
add s0, t6, t6         #
#-----------------------
flush_pipeline
assert_value s0, 0x222





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
