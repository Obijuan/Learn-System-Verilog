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

# -----------------------------------------------
# forward from mem instr (mem followed by wb)
test_mem_wb:
    addi t2, zero, 17
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 17

test_mem_wb_1_nop:
    addi t2, zero, 18
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    nop                          #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 18

test_mem_wb_2_nop:
    addi t2, zero, 19
    flush_pipeline
    sw   t2, 0(t4)
    flush_pipeline
    # ----------------------------
    lw   t5, 0(t4)               #
    nop                          #
    nop                          #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 19

# -----------------------------------------------
# forward from wb instr (wb followed by exe)
test_wb_exe:
    addi t2, zero, 20
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    addi t6, t5, 0x123           #
    # ----------------------------
    flush_pipeline
    assert_value t6, (20 + 0x123)

test_wb_exe_1_nop:
    addi t2, zero, 21
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    addi t6, t5, 0x456           #
    # ----------------------------
    flush_pipeline
    assert_value t6, (21 + 0x456)

test_wb_exe_2_nop:
    addi t2, zero, 22
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    nop                          #
    addi t6, t5, 0x789           #
    # ----------------------------
    flush_pipeline
    assert_value t6, (22 + 0x789)

# -----------------------------------------------
# forward from wb instr (wb followed by mem)
test_wb_mem:
    addi t2, zero, 23
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 23

test_wb_mem_1_nop:
    addi t2, zero, 24
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 24

test_wb_mem_2_nop:
    addi t2, zero, 25
    flush_pipeline
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    nop                          #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 25

# -----------------------------------------------
# forward from wb instr (wb followed by wb)
test_wb_wb:
    addi t2, zero, (26<<2) # mtvec[1:0] = 0b00
    flush_pipeline
    csrw mtvec,    zero
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    csrw mtvec, t5               #
    # ----------------------------
    flush_pipeline
    csrr t6, mtvec
    flush_pipeline
    assert_value t6, (26<<2)

test_wb_wb_1_nop:
    addi t2, zero, (27<<2)
    flush_pipeline
    csrw mtvec,    zero
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    csrw mtvec, t5               #
    # ----------------------------
    flush_pipeline
    csrr t6, mtvec
    flush_pipeline
    assert_value t6, (27<<2)

test_wb_wb_2_nop:
    addi t2, zero, (28<<2)
    flush_pipeline
    csrw mtvec,    zero
    csrw mscratch, t2
    flush_pipeline
    # ----------------------------
    csrr t5, mscratch            #
    nop                          #
    nop                          #
    csrw mtvec, t5               #
    # ----------------------------
    flush_pipeline
    csrr t6, mtvec
    flush_pipeline
    assert_value t6, (28<<2)

# -----------------------------------------------
# forward from previous instructon
test_fw_prev_instr_exe_exe_exe:
    addi t2, zero, 29
    flush_pipeline
    # ----------------------------
    lui  t5,     0xdeadb         #
    slli t5, t5, 12              #
    add  t6, t5, t1              #
    # ----------------------------
    flush_pipeline
    assert_value t6, (0xdb000000 + 1)





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
