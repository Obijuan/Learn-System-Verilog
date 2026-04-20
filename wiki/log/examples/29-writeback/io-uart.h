#-- Direccion base de la UART
.equ UART_BASE, 0x210000

#-- Offset de los registros de la UART
.equ UART_DATA, 0x0
.equ UART_RXSTATUS, 0x2
.equ UART_TXSTATUS, 0x3

#-- Registro de status del receptor
#<-------- RX STATUS ---------> 
#|          23...16           ||
#| 23-19|   18  |  17 |  16   ||
#| xxxxx|RX_FULL|RX_IE|RX_ERR ||
.equ RX_FULL, 0x4
.equ RX_IE, 0x2
.equ RX_ERR, 0x1

#-- Registro de status del transmisor
#<--------- TX STATUS ---------> 
#|           31...24           ||
#| 31-27|   26   |  25 |  24   ||
#| xxxxx|TX_EMPTY|TX_IE|TX_ERR ||
.equ TX_EMPTY, 0x4
.equ TX_IE, 0x2
.equ TX_ERR, 0x1

