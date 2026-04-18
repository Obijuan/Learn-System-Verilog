#!/usr/bin/env bash

#-- Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'  #-- Color por defecto


apio raw -- init.mem init2.mem hardware.asc hardware2.asc


if [ $? -ne 0 ]; then
    echo -e $RED"> Abortando...\n"$RESET
    exit 1
fi


apio raw -- icepack _build/default/hardware.asc _build/default/hardware.bin

