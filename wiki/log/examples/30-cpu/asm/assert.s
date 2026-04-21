assert_equal:
 #-------------------------------------------------
 #-- assert_equal(val1, val2)
 #--
 #-- Asegurarse que los dos numeros son iguales
 #-- Si NO lo son, se aborta el test
 #--
 #-- ENTRADAS:
 #--   - a0 (val1): Valor 1: Valor devuelto
 #--   - a1 (val2): Valor 2: Valor esperado
 #--   - a2 (cod): Codigo a mostrar en los leds en caso de error
 #-- SALIDA:
 #--   - Ninguna
 #-------------------------------------------------
	STACK16
	PUSH2 s0, s1

	#-- Guardar los parametros
	mv s0, a0
	mv s1, a1

	#-- Comparar los numeros
	bne a0, a1, assert_equal_ne
	
	#-- Los valores son iguales
	j assert_equal_end

 assert_equal_ne: 
    #-- Los valores NO son iguales
	#-- Test NO pasado!
    sw a2, (gp)
	j .

 assert_equal_end:
	POP2 s0, s1
	UNSTACK16

