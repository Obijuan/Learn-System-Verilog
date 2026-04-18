.macro halt
    j .
.endm

.macro flush_pipeline
    nop
    nop
    nop
    nop
    nop
.endm

.macro fail
    sw t2, 0(gp)
    halt
.endm
