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

test_fw_prev_instr_mem_wb_wb:
    addi t2, zero, 31
    flush_pipeline
    sw   t2, 0(t4)
    csrw mscratch, t1
    flush_pipeline
    # ----------------------------
    lw    t5, 0(t4)              #
    csrrw t5, mscratch, t5       #
    csrrw t6, mscratch, t5       #
    # ----------------------------
    flush_pipeline
    assert_value t6, 31
    flush_pipeline
    csrr  t6, mscratch
    flush_pipeline
    assert_value t6, 1

# -----------------------------------------------
# forward from first instructon
test_fw_first_instr_exe_mem_wb:
    addi t2, zero, 32
    flush_pipeline
    # ----------------------------
    add  t5, t1, t2              #
    sw   t5, 0(t4)               #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, (32 + 1)
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, (32 + 1)

test_fw_first_instr_mem_exe_wb:
    addi t2, zero, 33
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    add  t6, t1, t5              #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    assert_value t6, (33 + 1)
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 33

test_fw_first_instr_wb_exe_mem:
    addi t2, zero, 34
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrrw t5, mscratch, t1       #
    add   t6, t5, t1             #
    sw    t5, 0(t4)              #
    # ----------------------------
    flush_pipeline
    assert_value t6, (34 + 1)
    flush_pipeline
    lw    t6, 0(t4)
    flush_pipeline
    assert_value t6, 34

# -----------------------------------------------
# forward from first instructon with dummy
test_fw_wb_dummyMem_exe:
    addi t2, zero, 35
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    sw   t2, 0(t4)               #
    addi t6, t5, -0x123          #
    # ----------------------------
    flush_pipeline
    assert_value t6, (35 - 0x123)

test_fw_mem_dummyExe_wb:
    addi t2, zero, 36
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    sll  t6, t1, zero            #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 36

test_fw_mem_dummyMem_exe:
    addi t2, zero, 37
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    lw   t6, 0(t4)               #
    addi t6, t5, -0x123          #
    # ----------------------------
    flush_pipeline
    assert_value t6, (37 - 0x123)

test_fw_wb_mem_dummyExe:
    addi t2, zero, 38
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    sw   t5, 0(t4)               #
    addi t6, t1, -0x123          #
    # ----------------------------
    flush_pipeline
    lw    t6, 0(t4)
    flush_pipeline
    assert_value t6, 38


# ------------------------------
# Override destination register
# exe - exe
addi t2, zero, 39
flush_pipeline
# ---------------------
addi t5, zero, 5      #
addi t5, x0, 6        #
addi t6, t5, 0        #
#----------------------
flush_pipeline
assert_value t6, 6

# ------------------------------
# Override destination register
# exe - exe
addi t2, zero, 40
flush_pipeline
# ---------------------
addi t5, zero, 0x11   #
addi t5, zero, 0x22   #
add t6, t5, zero      #
#----------------------
flush_pipeline
assert_value t6, 0x22

# ------------------------------
# Override destination register
# exe - exe
addi t2, zero, 41
flush_pipeline
# ----------------------
addi t5, zero, 0x111   #
addi t5, zero, 0x222   #
add t6, zero, t5       #
#-----------------------
flush_pipeline
assert_value t6, 0x222

# -------------------------------
# Override destination register
# exe - exe
addi t2, zero, 42
flush_pipeline
# ----------------------
addi t5, zero, 0x111   #
addi t5, zero, 0x222   #
add t6, t5, t5         #
#-----------------------
flush_pipeline
assert_value t6, 0x444



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
