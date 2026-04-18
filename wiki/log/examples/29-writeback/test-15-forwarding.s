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

# -----------------------------------------------
# forward from exe instr (exe followed by exe)
test_exe_exe:
    addi t2, zero, 2
    li t1, 1
    flush_pipeline
    # ----------------------------
    addi t5, zero, 1             #
    add  t6, t1, t5              #
    # ----------------------------
    flush_pipeline
    assert_value t6, 2

test_exe_exe_1_nop:
    addi t2, zero, 3
    flush_pipeline
    # ----------------------------
    addi t5, zero, 1             #
    nop                          #
    add  t6, t1, t5              #
    # ----------------------------
    flush_pipeline
    assert_value t6, 2

test_exe_exe_2_nop:
    addi t2, zero, 4
    flush_pipeline
    # ----------------------------
    addi t5, zero, 1             #
    nop                          #
    nop                          #
    add  t6, t1, t5              #
    # ----------------------------
    flush_pipeline
    assert_value t6, 2

# -----------------------------------------------
# forward from exe instr (exe followed by mem)
test_exe_mem:
    addi t2, zero, 5
    la t4, var
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x123         #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 0x123

test_exe_mem_1_nop:
    addi t2, zero, 6
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x456         #
    nop                          #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 0x456

test_exe_mem_2_nop:
    addi t2, zero, 7
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x789         #
    nop                          #
    nop                          #
    sw   t5, 0(t4)               #
    # ----------------------------
    flush_pipeline
    lw   t6, 0(t4)
    flush_pipeline
    assert_value t6, 0x789

# -----------------------------------------------
# forward from exe instr (exe followed by wb)
test_exe_wb:
    addi t2, zero, 8
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x123         #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 0x123

test_exe_wb_1_nop:
    addi t2, zero, 9
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x456         #
    nop                          #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 0x456

test_exe_wb_2_nop:
    addi t2, zero, 10
    flush_pipeline
    # ----------------------------
    addi t5, zero, 0x789         #
    nop                          #
    nop                          #
    csrw mscratch, t5            #
    # ----------------------------
    flush_pipeline
    csrr t6, mscratch
    flush_pipeline
    assert_value t6, 0x789



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
