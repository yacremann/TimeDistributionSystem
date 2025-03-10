VERILOG_SOURCES = $(PWD)/../protocol/data_frames.sv $(PWD)/crc_calc.sv $(PWD)/FrameReceiver.sv
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=FrameReceiver
# MODULE is the name of the Python test file:
MODULE=TestPulseIdReceiver


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps
# Tell it to trace the result
EXTRA_ARGS += --trace --trace-structs -I$(PWD)/../../general/protocol/


include $(shell cocotb-config --makefiles)/Makefile.sim

