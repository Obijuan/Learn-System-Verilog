#-- Punto de entrada del programa de prueba
.global __reset
__reset:
    #-- Se pone primero para ver algo en los leds (op=1)
    auipc x2, 0x41  #-- op=1
    lui x1, 0x40    #-- op=0
    jal x3, etiq1   #-- op=2

etiq1:
    jalr x4, x5       #-- op=3
    beq x6, x7, etiq2 #-- op=4

etiq2:
    bne x8, x9, etiq3 #-- op=5

etiq3:
    blt x10, x11, etiq4 #-- op=6
    bge x12, x13, etiq5 #-- op=7

etiq4:
    bltu x14, x15, etiq6 #-- op=8

etiq5:
    bgeu x16, x17, etiq7 #-- op=9

etiq6:
etiq7:
    lb x18, 0x42(x19)  #-- op=10
    lh x20, 0x44(x21)  #-- op=11
    lw x22, 0x50(x23)  #-- op=12
    lbu x24, 0x60(x25) #-- op=13
    lhu x26, 0x70(x27) #-- op=14
    sb x28, 0x80(x29)  #-- op=15
    sh x30, 0x90(x31)  #-- op=16
    sw x31, 0xA0(x0)   #-- op=17
    addi x1, x2, 0xA1  #-- op=18
    slti x3, x4, 0xA2  #-- op=19
    sltiu x5, x6, 0xA3 #-- op=20
    xori x7, x8, 0xA4  #-- op=21
    ori x9, x10, 0xA5  #-- op=22
    andi x11, x12, 0xA6 #-- op=23
    slli x13, x14, 0x01 #-- op=24
    srli x15, x16, 0x02 #-- op=25
    srai x17, x18, 0x03 #-- op=26
    add x19, x20, x21   #-- op=27
    sub x22, x23, x24   #-- op=28
    sll x25, x26, x27   #-- op=29
    slt x28, x29, x30   #-- op=30
    sltu x31, x31, x0   #-- op=31
    xor x1, x2, x3      #-- op=32
    srl x4, x5, x6      #-- op=33
    sra x7, x8, x9      #-- op=34
    or x10, x11, x12    #-- op=35
    and x13, x14, x15   #-- op=36
    fence               #-- op=37
    fence.i             #-- op=38
    ecall               #-- op=39
    ebreak              #-- op=40
    csrrw x16, mscratch, x17  #-- op=41
    csrrs x18, mscratch, x19  #-- op=42
    csrrc x20, mscratch, x21  #-- op=43
    csrrwi x22, mscratch, 0x10 #-- op=44
    csrrsi x23, mscratch, 0x11 #-- op=45
    csrrci x24, mscratch, 0x12 #-- op=46
    mret                       #-- op=47
    wfi                        #-- op=48

inf: j inf
