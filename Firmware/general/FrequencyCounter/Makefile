VERILOG_SOURCES = $(PWD)/gray.sv $(PWD)/synchronizer.sv $(PWD)/FrequencyCounter.sv  
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=TestFrequencyCounter
# MODULE is the name of the Python test file:
MODULE=TestFrequencyCounter


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps
# Tell it to trace the result
EXTRA_ARGS += --trace --trace-structs 


include $(shell cocotb-config --makefiles)/Makefile.sim

