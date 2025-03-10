VERILOG_SOURCES = $(PWD)/ApbBus.sv $(PWD)/BusTester.sv
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=BusTester
# MODULE is the name of the Python test file:
MODULE=Testbench


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps
# Tell it to trace the result
EXTRA_ARGS += --trace --trace-structs --Wno-UNOPT


include $(shell cocotb-config --makefiles)/Makefile.sim

