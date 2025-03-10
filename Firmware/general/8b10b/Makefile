VERILOG_SOURCES = $(PWD)/Decode_8b10b.v $(PWD)/Encode_8b10b.v $(PWD)/testsetup.sv
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=testsetup
# MODULE is the name of the Python test file:
MODULE=Test8b10b


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps
# Tell it to trace the result
EXTRA_ARGS += --trace --trace-structs


include $(shell cocotb-config --makefiles)/Makefile.sim

