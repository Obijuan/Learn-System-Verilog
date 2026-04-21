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

    j start

    # exception interrupt handler
irq_handler_exceptions:
    # store current mcause
    csrr s5, mcause
    lui  s6,     %hi(interrupt_var)
    addi s6, s6, %lo(interrupt_var)
    sw   s5, 0(s6)
    # return to next instruction
    csrr s5, mscratch
    csrw mepc, s5
    mret
    # jump to reset if this code snipped reached
    flush_pipeline
    beq  zero, zero, __reset

start:

    #-- Prueba de assert
    #-- Si falla se muestra 1 en los leds (numero de test fallado)
    li t0, 0xAA
    ASSERT_EQUAL t0, 0xAA, 1


#----- Init....
    la t4, var
    li t1, 1

# -----------------------------------------------
# Exceptions
init_exceptions:
    # set interrupt handler
    lui  t5,     %hi(irq_handler_exceptions)
    addi t5, t5, %lo(irq_handler_exceptions)
    csrw mtvec, t5
    # set address of interrupt variable
    lui  t6,     %hi(interrupt_var)
    addi t6, t6, %lo(interrupt_var)

# fetch misaligned
test_fetch_misaligned:
    addi t2, zero, 4
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(fetch_misaligned_check)
    addi t5, t5, %lo(fetch_misaligned_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    lui  t5,     %hi(fetch_misaligned_check)
    addi t5, t5, %lo(fetch_misaligned_check)
    addi t5, t5, 2
    jr   t5
    # check if correct trap triggered
    fetch_misaligned_check:
    lw   t5, 0(t6)
    assert_value t5, 0

# fetch fault
test_fetch_fault:
    addi t2, zero, 5
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(fetch_fault_check)
    addi t5, t5, %lo(fetch_fault_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    j 0
    # check if correct trap triggered
    fetch_fault_check:
    lw   t5, 0(t6)
    assert_value t5, 1

# illegal instruction
test_illegal_instruction:
    addi t2, zero, 6
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(illegal_instruction_check)
    addi t5, t5, %lo(illegal_instruction_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    .word 0x0
    # check if correct trap triggered
    illegal_instruction_check:
    lw   t5, 0(t6)
    assert_value t5, 2


# ebreak
test_ebreak:
    addi t2, zero, 7
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(ebreak_check)
    addi t5, t5, %lo(ebreak_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    ebreak
    # check if correct trap triggered
    ebreak_check:
    lw   t5, 0(t6)
    assert_value t5, 3

# load misaligned
test_load_misaligned:
    addi t2, zero, 8
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(load_misaligned_check)
    addi t5, t5, %lo(load_misaligned_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    lw   t5, 2(t4)
    # check if correct trap triggered
    load_misaligned_check:
    lw   t5, 0(t6)
    assert_value t5, 4

# load fault
test_load_fault:
    addi t2, zero, 9
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(load_fault_check)
    addi t5, t5, %lo(load_fault_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    lw   t5, 0(zero)
    # check if correct trap triggered
    load_fault_check:
    lw   t5, 0(t6)
    assert_value t5, 5

# store misaligned
test_store_misaligned:
    addi t2, zero, 10
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(store_misaligned_check)
    addi t5, t5, %lo(store_misaligned_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    sw   t5, 2(t4)
    # check if correct trap triggered
    store_misaligned_check:
    lw   t5, 0(t6)
    assert_value t5, 6

# store fault
test_store_fault:
    addi t2, zero, 11
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(store_fault_check)
    addi t5, t5, %lo(store_fault_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    sw   t5, 0(zero)
    # check if correct trap triggered
    store_fault_check:
    lw   t5, 0(t6)
    assert_value t5, 7

# ecall
test_ecall:
    addi t2, zero, 12
    sw   t2, 0(t6)
    flush_pipeline
    # set trap return address
    lui  t5,     %hi(ecall_check)
    addi t5, t5, %lo(ecall_check)
    csrw mscratch, t5
    flush_pipeline
    # trigger trap
    ecall
    # check if correct trap triggered
    ecall_check:
    lw   t5, 0(t6)
    assert_value t5, 11


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
interrupt_var:
    .word 0xdeadbeef
