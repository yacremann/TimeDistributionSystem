#!/bin/sh

# build the software
cd Software/tinyduino_lib
make
cd ..
make
cd ..

# path to the qurtus installation
QUARTUS_PATH=/opt/intelFPGA_lite/23.1std/quartus

QSYS_PATH=$QUARTUS_PATH/sopc_builder/bin

LOCAL_PATH=$(pwd)

# generate the FLASH memory
$QSYS_PATH/qsys-generate ROM.qsys --block-symbol-file --output-directory=$LOCAL_PATH/ROM --family="MAX 10" --part=10M16SCE144A7G
$QSYS_PATH/qsys-generate ROM.qsys --synthesis=VERILOG --output-directory=$LOCAL_PATH/ROM --family="MAX 10" --part=10M16SCE144A7G

# Build the entire thing
$QUARTUS_PATH/bin/quartus_sh --flow compile Transmitter

# Generate the programming file with everything inside (software and hardware)
$QUARTUS_PATH/bin/quartus_cpf -c generate_ufm_prog_file.cof
