#!/usr/bin/env bash

#-- Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'  #-- Color por defecto

#-- Herramientas
BIN="/opt/riscv32i/bin"
SIZE=$BIN"/riscv32-unknown-elf-size"
GCC=$BIN"/riscv32-unknown-elf-gcc"
OBJDUMP=$BIN"/riscv32-unknown-elf-objdump"
OBJCOPY=$BIN"/riscv32-unknown-elf-objcopy"

if [ -z "$1" ]; then
    echo "Uso: $0 fichero"
    echo "Ejemplo: $0 test-24-uart-puts.s"
    echo ""
    exit 1
fi


#-- Nombre del fichero a ensamblar, sin extension
NAME=$1
NAME="${NAME%.*}" #-- Quitar extension

#-- Calcular tamaño
echo -e $BLUE"\n• Calculando tamaño:"$RESET
$SIZE -x $NAME.elf

if [ $? -ne 0 ]; then
    echo -e $RED"> Abortando...\n"$RESET
    exit 1
fi

echo ""

