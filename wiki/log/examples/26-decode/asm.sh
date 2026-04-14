#!/usr/bin/env bash

#-- Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'  #-- Color por defecto

#-- Herramientas
BIN="/opt/riscv32i/bin"
GCC=$BIN"/riscv32-unknown-elf-gcc"
OBJDUMP=$BIN"/riscv32-unknown-elf-objdump"
OBJCOPY=$BIN"/riscv32-unknown-elf-objcopy"

if [ -z "$1" ]; then
    echo "Uso: $0 fichero"
    echo "Ejemplo: $0 test-synth-01-decode"
    echo ""
    exit 1
fi

#-- Nombre del fichero a ensamblar, sin extension
NAME=$1
NAME="${NAME%.*}" #-- Quitar extension

#-- Ensamblado
echo -e $BLUE"\n• Ensamblando:"$RESET
$GCC -nostdlib -nostartfiles  -T hades-v.ld -o $NAME.elf $NAME.s

if [ $? -ne 0 ]; then
    echo -e $RED"> Abortando...\n"$RESET
    exit 1
fi

#-- Desensamblado
echo ""
echo -e $BLUE"• Desensamblado: ${RESET}"$NAME.dis
$OBJDUMP -d -r -t -S $NAME.elf > $NAME.dis

#-- Fichero ejecutable en binario
echo -e $BLUE"• Ejecutable binario: ${RESET}"$NAME.bin
$OBJCOPY -O binary $NAME.elf $NAME.bin

#-- Fichero ejecutable para integrar en la memoria
#-- del diseño en verilog
echo -e $BLUE"• Ejecutable verilog: ${RESET}"$NAME.mem
$OBJCOPY -I binary -O verilog --verilog-data-width 4 \
  --reverse-bytes=4 $NAME.bin $NAME.mem

#-- Es el nuevo init.mem
cp $NAME.mem init.mem
echo ""

