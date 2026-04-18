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
# LUI ✅
test_lui:
    addi t2, zero, 2
    flush_pipeline
    lui  t6, %hi(0x12345678)
    assert_value t6, 0x12345000


# -----------------------------------------------
# AUIPC ✅
test_auipc:
    addi  t2, zero, 3
    flush_pipeline
    auipc t6, %hi(0x12345678)
    auipc t5, %hi(0x12345678)
    sub   t6, t5, t6
    assert_value t6, 4

# -----------------------------------------------
# JAL ✅  
test_jal:
    addi  t2, zero, 4
    flush_pipeline
    auipc t6, 0
    jal   t5, jal_target
    fail

    jal_target:
    sub t6, t5, t6
    addi x0, t6, 0

    assert_value t6, 8

# -----------------------------------------------
# JALR  ✅
test_jalr:
    addi  t2, zero, 5
    flush_pipeline
    auipc t6, 0
    lui   t5, %hi(jalr_target)
    jalr  t5, %lo(jalr_target)(t5)
    fail

    jalr_target:
    sub t6, t5, t6
    assert_value t6, 12

# -----------------------------------------------
# BRANCH 
test_beq: # ✅
    addi t2, zero, 6
    li t1, 1
    flush_pipeline
    beq  zero, t1,   beq_target_fail
    beq  zero, zero, beq_target
    beq_target_fail:
    fail
    beq_target:

test_bne: # ✅
    addi t2, zero, 7
    li t1, 1
    flush_pipeline
    bne  zero, zero, bne_target_fail
    bne  zero, t1,   bne_target
    bne_target_fail:
    fail
    bne_target:


test_blt: # ✅
    addi t2, zero, 8
    li t1, 1
    flush_pipeline
    blt  t1, zero, blt_target_fail
    blt  zero, t1, blt_target
    blt_target_fail:
    fail
    blt_target:


test_bge: # ✅
    addi t2, zero, 9
    li t1, 1
    bge  zero, t1, bge_target_fail
    bge  t1, zero, bge_target
    bge_target_fail:
    fail
    bge_target:











    #-- Tests pasado con exito
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


