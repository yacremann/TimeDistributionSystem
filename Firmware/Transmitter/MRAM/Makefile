VERILOG_SOURCES = $(PWD)/SPI_RW.sv $(PWD)/MRAM.sv 
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=MRAM
# MODULE is the name of the Python test file:
MODULE=TestMram


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps
# Tell it to trace the result
EXTRA_ARGS += --trace --trace-structs


include $(shell cocotb-config --makefiles)/Makefile.sim

