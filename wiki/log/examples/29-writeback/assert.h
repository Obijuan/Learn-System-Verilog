#----------------------------------------------------
#-- Compara que dos valores sean iguales
#-- El valor izquierdo es el devuelto por la funcion
#--   ES UN REGISTRO
#-- El valor derecho es el valor esperado. Es una
#--   constante
#----------------------------------------------------
.macro ASSERT_EQUAL reg:req, val:req, cod:req
	mv a0, \reg
	li a1, \val
    li a2, \cod
	jal assert_equal
.endm

