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
# ALU
init_alu_regs:
    flush_pipeline
    addi t5, zero, 6
    addi t6, zero, -0x123
    flush_pipeline

test_add:
    addi t2, zero, 29
    flush_pipeline
    add  s6, t6, t5
    assert_value s6, (-0x123 + 6)

test_sub:
    addi t2, zero, 30
    flush_pipeline
    sub s6, t6, t5
    assert_value s6, (-0x123 - 6)

test_sll:
    addi t2, zero, 31
    flush_pipeline
    sll s6, t6, t5
    assert_value s6, 0xffffb740 # -0x123 <<< 6

test_slt:
    addi t2, zero, 32
    flush_pipeline
    slt s6, t5, t6
    assert_value s6, 0
    slt s6, t6, t5
    assert_value s6, 1

test_sltu:
    addi t2, zero, 33
    flush_pipeline
    sltu s6, t6, t5
    assert_value s6, 0
    sltu s6, t5, t6
    assert_value s6, 1

test_xor:
    addi t2, zero, 34
    flush_pipeline
    xor s6, t6, t5
    assert_value s6, (-0x123 ^ 6)

test_srl:
    addi t2, zero, 35
    flush_pipeline
    srl s6, t6, t5
    assert_value s6, 0x03fffffb # -0x123 >>> 6

test_sra:
    addi t2, zero, 36
    flush_pipeline
    sra s6, t6, t5
    assert_value s6, 0xfffffffb # -0x123 >> 6

test_or:
    addi t2, zero, 37
    flush_pipeline
    or s6, t6, t5
    assert_value s6,  (-0x123 | 6)

test_and:
    addi t2, zero, 38
    flush_pipeline
    and s6, t6, t5
    assert_value s6,  (-0x123 & 6)


# -----------------------------------------------
# MISC-MEM
test_fence_i:
    addi t2, zero, 39
    flush_pipeline
    fence.i

# -----------------------------------------------
# SYSTEM
test_csrrw:
    addi t2, zero, 40
    flush_pipeline
    lui  t6, %hi(0xcafebabe)
    addi t6, t6, %lo(0xcafebabe)
    csrrw t6, mscratch, t6
    assert_value t6, 0

test_csrrs:
    addi t2, zero, 41
    flush_pipeline
    addi  t6, zero, 0xF0
    csrrs t6, mscratch, t6
    assert_value t6, 0xcafebabe

test_csrrc:
    addi t2, zero, 42
    flush_pipeline
    addi  t6, zero, 0x0F
    csrrc t6, mscratch, t6
    assert_value t6, 0xcafebafe

test_csrrwi:
    addi t2, zero, 43
    flush_pipeline
    csrrwi t6, mscratch, 0x0f
    assert_value t6, 0xcafebaf0

test_csrrsi:
    addi t2, zero, 44
    flush_pipeline
    csrrsi t6, mscratch, 0x10
    assert_value t6, 0x0f

test_csrrci:
    addi t2, zero, 45
    flush_pipeline
    csrrci t6, mscratch, 0x01
    assert_value t6, 0x1f

test_csrr:
    addi t2, zero, 46
    flush_pipeline
    csrrs t6, mscratch, zero
    csrrc t6, mscratch, zero
    csrrs t6, mscratch, zero
    assert_value t6, 0x1e

test_csrri:
    addi t2, zero, 47
    flush_pipeline
    csrrsi t6, mscratch, 0
    csrrci t6, mscratch, 0
    csrrsi t6, mscratch, 0
    assert_value t6, 0x1e

test_mtvec:
    addi t2, zero, 48
    flush_pipeline
    lui   t6, %hi(test_mepc)
    addi  t6, t6, %lo(test_mepc)
    csrrw t6, mtvec, t6
    csrrs t6, mtvec, zero
    assert_value_adr t6, test_mepc

test_ecall:
    addi t2, zero, 49
    flush_pipeline
    ecall
    fail

test_mepc:







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

    .align 4
var:
    .word 0xcafebabe

#----- Dependencias
.include "assert.s"
.include "delay.s"
.include "seq.s"


