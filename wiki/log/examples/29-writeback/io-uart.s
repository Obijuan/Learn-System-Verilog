#--------------------------------------------------------------
#-- uart_wait_tx_ready()
#--
#-- Esperar hasta que el bit TX_EMPTY del transmisor
#-- se ponga a 1
#--
#-- El registro tp debe contener la direccion base de la uart
#--------------------------------------------------------------
uart_wait_tx_ready:
    #-- Leer el registro de status de la UART
    lw t0, 0(tp)
    
    #-- Aislar el bit TX_EMPTY
    li t1, TX_EMPTY
    and t0, t0, t1
    
    #-- Si el bit es 0, el transmisor no esta listo
    #-- repetimos la accion hasta que se ponga a 1
    beq t0, zero, uart_wait_tx_ready

    #-- Retornar al caller
    ret


#---------------------------------------------------------------
#-- putchar(c): Imprimir un caracter
#--
#-- ENTRADA:
#--   - a0 (c): Carácter a imprimir
#--
#-- El registro tp debe contener la direccion base de la uart
#---------------------------------------------------------------
putchar:

	STACK16
	
	#-- Esperar a que el transmisor esté listo
	jal uart_wait_tx_ready
	
	#-- Escribir el caracter en el registro de datos
	sw a0, 0(tp)
	
	#-- Recuperar la dirección de retorno y liberar la pila
	UNSTACK16

