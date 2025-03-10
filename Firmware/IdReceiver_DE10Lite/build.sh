#!/bin/sh

# path to the qurtus installation
QUARTUS_PATH=/opt/intelFPGA_lite/23.1std/quartus

QSYS_PATH=$QUARTUS_PATH/sopc_builder/bin

LOCAL_PATH=$(pwd)

# Build the entire thing
$QUARTUS_PATH/bin/quartus_sh --flow compile EmbeddedReceiverDemo

