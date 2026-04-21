#!/usr/bin/env bash

#-- Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'  #-- Color por defecto

#-- Insertar el fichero init.mem en el bitstream directamente
apio raw -- icebram rtl/icebram.mem _build/init.mem \
     < _build/hardware.asc > _build/hardware2.asc


if [ $? -ne 0 ]; then
    echo -e $RED"> Error! Abortando...\n"$RESET
    exit 1
fi


#-- Crear el nuevo Bitstream!
apio raw -- icepack _build/hardware2.asc _build/hardware.bin

if [ $? -ne 0 ]; then
    echo -e $RED"> Error! Abortando...\n"$RESET
    exit 1
fi

echo -e $GREEN"Exito!\n"$RESET

