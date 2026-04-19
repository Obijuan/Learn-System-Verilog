#!/usr/bin/env bash

#-- Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'  #-- Color por defecto

#-- Obtener el fichero de memoria inicial, generado por icebram
cp icebram.mem init.mem

#-- Insertar el fichero init2.mem en el bitstream directamente
apio raw -- icebram init.mem init2.mem < _build/default/hardware.asc > _build/default/hardware2.asc


if [ $? -ne 0 ]; then
    echo -e $RED"> Error! Abortando...\n"$RESET
    exit 1
fi


#-- Crear el nuevo Bitstream!
apio raw -- icepack _build/default/hardware2.asc _build/default/hardware2.bin

if [ $? -ne 0 ]; then
    echo -e $RED"> Error! Abortando...\n"$RESET
    exit 1
fi

echo -e $GREEN"Exito!\n"$RESET

