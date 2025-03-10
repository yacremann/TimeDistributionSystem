# Time Distribution System for Lab Based Experiments

This project implements a time distribution system for laboratory based experiments using pulsed lasers.
It consists of a transmitter and several receivers. The transmitter generates a unique pulse-id number for
each laser pulse. This pulse-id, together with configuration information is transmitted to the receivers
over twisted-pair cables (use Cat 6A cables only!). A magnetic RAM is used to store the last value and to
recover after a power outage.

The receivers decode the pulse-id send it to FPGAs on individual instruments (framegrabber boards, digitizers, ...)
for time stamping the data. In addition, the receivers generate low-jitter trigger signals. These can be configured
from the transmitter.

The project contains the following components:
- Boards: Schematics and layouts of the printed circuit boards for the receiver and transmitter
- Firmware: Logic on the FPGAs as well as firmware running on an embedded RISC-V processor for the transmitter and receivers
- Tango: Device servers for the transmitter and to configure the trigger channels of the receivers (see tango-controls.org)
- Notes: Presentation with the block diagrams of the system

## Requirements:
- For simulating the individual components of the firmware: Cocotb, Verilator
- For synthesis: Quartus (intel) v. 23.1 standard edition
- For the software on the RISC-V: gcc for RV32IM (see https://github.com/SpinalHDL/VexRiscv)
- Tango control system: https://tango-controls.org


The project contains the following 3rd party components:
Firmware:
- CRC generator (https://github.com/hellgate202/crc_calc.git)
- Softcore: Based on the VexRiscV project (https://github.com/SpinalHDL/VexRiscv)
- TinyDuino_lib: developed by Domenic Wüthrich as a semester project at ETH Zurich, institute for integrated systems.
- fifo_v3: https://github.com/pulp-platform/common_cells/blob/master/src/fifo_v3.sv (ETH Zurich and University of Bologna)

License:
GNU Public License v3.0 (see LICENSE)
