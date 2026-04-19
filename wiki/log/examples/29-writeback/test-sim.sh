#!/usr/bin/env bash

#-- Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RESET='\033[0m'  #-- Color por defecto

#------------------------------------
NAME1="test-12-assert.s"
echo ""
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET
echo "➡️  Probando: $NAME1"
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET

./asm.sh  $NAME1 && ./sim.sh

#------------------------------------
NAME2="test-13-ops.s"
echo ""
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET
echo "➡️  Probando: $NAME2"
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET

./asm.sh  $NAME2 && ./sim.sh

#------------------------------------
NAME3="test-14-ops2.s"
echo ""
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET
echo "➡️  Probando: $NAME3"
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET

./asm.sh  $NAME3 && ./sim.sh

#------------------------------------
NAME4="test-15-forwarding.s"
echo ""
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET
echo "➡️  Probando: $NAME4"
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET

./asm.sh  $NAME4 && ./sim.sh

#------------------------------------
NAME5="test-16-forwarding2.s"
echo ""
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET
echo "➡️  Probando: $NAME5"
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET

./asm.sh  $NAME5 && ./sim.sh

#------------------------------------
NAME6="test-17-forwarding3.s"
echo ""
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET
echo "➡️  Probando: $NAME6"
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET

./asm.sh  $NAME6 && ./sim.sh

#------------------------------------
NAME7="test-18-forwarding4.s"
echo ""
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET
echo "➡️  Probando: $NAME7"
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET

./asm.sh  $NAME7 && ./sim.sh

#------------------------------------
NAME8="test-19-trap.s"
echo ""
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET
echo "➡️  Probando: $NAME8"
echo -e $YELLOW"─────────────────────────────────────────────────────"$RESET

./asm.sh  $NAME8 && ./sim.sh


#------ CLEANUP
rm *.elf *.bin *.dis


