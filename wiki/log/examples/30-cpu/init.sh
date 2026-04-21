#!/usr/bin/env bash

#-- Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'  #-- Color por defecto

#-- Directorio de construccion
BUILD_DIR="_build"

#-- Crear directorio de construccion, si no lo está ya
mkdir -p $BUILD_DIR

#-- El archivo init.mem usado es el que tiene contenido
#-- aleatorio: icebram.mem
cp rtl/icebram.mem _build/init.mem

echo -e $GREEN"Usando init.mem generado por icebram"$RESET

