#--------------------------------------------------
#-- puts(cad): Imprimir una cadena en la consola
#--
#-- ENTRADA:
#--   - a0 (cad): Puntero a la cadena a imprimir
#-------------------------------------------------
puts:
    
    #-- Crear la pila y guardar la direccion de retorno
    STACK16
    
    #-- Guardar s0
    sw s0, 0(sp)
    
    #-- s0: Puntero a la cadena
    mv s0, a0
    
  puts_next:
    #-- Leer caracter de la memoria
    lb a0, 0(s0)
    
    #-- Si el caracter es '\0', terminar
    beq a0, zero, puts_end
    
    #-- Imprimir caracter actual
    jal putchar
    
    #-- Apuntar al siguiente caracter
    addi s0, s0, 1
    
    #-- Repetir
    j puts_next


  puts_end:
	#-- Recuperar s0
	lw s0, 0(sp)
	
	#-- Recuperar direccion de retorno y liberar pila
    UNSTACK16

