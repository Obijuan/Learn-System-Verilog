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

test_bltu: # ✅
    addi t2, zero, 10
    li t1, 1
    flush_pipeline
    addi t6, zero, -1
    bltu t6, zero, bltu_target_fail
    bltu zero, t6, bltu_target
    bltu_target_fail:
    fail
    bltu_target:

test_bgeu: # ✅ 
    addi t2, zero, 11
    li t1, 1
    flush_pipeline
    addi t6, zero, -1
    bgeu zero, t6, bgeu_target_fail
    bgeu t6, zero, bgeu_target
    bgeu_target_fail:
    fail
    bgeu_target:


# -----------------------------------------------
# LOAD
test_lb:  # ✅
    addi t2, zero, 12
    la t4, var
    flush_pipeline
    lb   t6, 0(t4)
    assert_value t6, 0xffffffbe
    lb   t6, 1(t4)
    assert_value t6, 0xffffffba
    lb   t6, 2(t4)
    assert_value t6, 0xfffffffe
    lb   t6, 3(t4)
    assert_value t6, 0xffffffca

test_lh: # ✅
    addi t2, zero, 13
    flush_pipeline
    lh   t6, 0(t4)
    assert_value t6, 0xffffbabe
    lh   t6, 2(t4)
    assert_value t6, 0xffffcafe

test_lw: # ✅
    addi t2, zero, 14
    flush_pipeline
    lw   t6, 0(t4)
    assert_value t6, 0xcafebabe

test_lbu: # ✅
    addi t2, zero, 15
    flush_pipeline
    lbu  t6, 0(t4)
    assert_value t6, 0x000000be
    lbu  t6, 1(t4)
    assert_value t6, 0x000000ba
    lbu  t6, 2(t4)
    assert_value t6, 0x000000fe
    lbu  t6, 3(t4)
    assert_value t6, 0x000000ca

test_lhu: # ✅
    addi t2, zero, 16
    flush_pipeline
    lhu  t6, 0(t4)
    assert_value t6, 0x0000babe
    lhu  t6, 2(t4)
    assert_value t6, 0x0000cafe


# -----------------------------------------------
# STORE
test_sb: # ✅
    addi t2, zero, 17
    flush_pipeline
    lui  t5,     %hi(0xdeadbeef)
    addi t5, t5, %lo(0xdeadbeef)
    sb   t5, 0(t4)
    lw   t6, 0(t4)
    assert_value t6, 0xcafebaef


test_sh: # ✅
    addi t2, zero, 18
    flush_pipeline
    sh   t5, 0(t4)
    lw   t6, 0(t4)
    assert_value t6, 0xcafebeef

test_sw: # ✅
    addi t2, zero, 19
    flush_pipeline
    sw   t5, 0(t4)
    lw   t6, 0(t4)
    assert_value t6, 0xdeadbeef

# -----------------------------------------------
# IMMEDIATE
test_addi:  # ✅
    addi t2, zero, 20
    flush_pipeline
    addi t6, zero, 0x123
    addi t6, t6,   0x456
    assert_value t6, (0x123 + 0x456)

test_slti: # ✅
    addi t2, zero, 21
    flush_pipeline
    slti t6, zero, -1
    assert_value t6, 0
    slti t6, zero, +1
    assert_value t6, 1

test_sltiu: # ⬅️
    addi  t2, zero, 22
    flush_pipeline
    sltiu t6, zero, -1
    assert_value t6, 1
    sltiu t6, zero, +1
    assert_value t6, 1

test_xori:
    addi t2, zero, 23
    flush_pipeline
    addi t6, zero, 0x321
    xori t6, t6,   0x789
    assert_value t6, (0x321 ^ 0x789)

test_ori:
    addi t2, zero, 24
    flush_pipeline
    addi t6, zero, 0x321
    ori  t6, t6,   0x789
    assert_value t6, (0x321 | 0x789)

test_andi:
    addi t2, zero, 25
    flush_pipeline
    addi t6, zero, 0x321
    andi t6, t6,   0x789
    assert_value t6, (0x321 & 0x789)

test_slli:
    addi t2, zero, 26
    flush_pipeline
    addi t6, zero, -16 # 0b1...10000
    slli t6, t6,   4
    assert_value t6, 0xffffff00

test_srli:
    addi t2, zero, 27
    flush_pipeline
    addi t6, zero, -16
    srli t6, t6,   4
    assert_value t6, 0x0fffffff

test_srai:
    addi t2, zero, 28
    flush_pipeline
    addi t6, zero, -16
    srai t6, t6,   4
    assert_value t6, 0xffffffff






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

    .align 4
var:
    .word 0xcafebabe

#----- Dependencias
.include "assert.s"
.include "delay.s"
.include "seq.s"


