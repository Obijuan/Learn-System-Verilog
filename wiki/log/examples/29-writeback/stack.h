#-------------------------------------------------------
#-- Crear una pila de 16 bytes
#-- Espacio para 4 registros (offsets 0 - 8)
#-- La direccion de retorno se guarda en el offset 12
#-------------------------------------------------------
.macro STACK16
  addi sp, sp, -16
  sw ra, 12(sp)
.endm

#-------------------------------------------------------
#-- Crear una pila de 32 bytes
#-- Espacio para 8 registros (offsets 0 - 24)
#-- La direccion de retorno se guarda en el offset 28
#-------------------------------------------------------
.macro STACK32
  addi sp, sp, -32
  sw ra, 28(sp)
.endm


#----------------------------------------
#-- Liberar la pila de 16 bytes
#-- Recuperar la direccion de retorno
#-- RETORNAR DE LA FUNCION!
#----------------------------------------
.macro UNSTACK16
  lw ra, 12(sp)
  addi sp, sp, 16
  ret
.endm

#----------------------------------------
#-- Liberar la pila de 32 bytes
#-- Recuperar la direccion de retorno
#-- RETORNAR DE LA FUNCION!
#----------------------------------------
.macro UNSTACK32
  lw ra, 28(sp)
  addi sp, sp, 32
  ret
.endm
