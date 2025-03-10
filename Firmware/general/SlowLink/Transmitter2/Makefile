VERILOG_SOURCES = $(PWD)/data_frames.sv $(PWD)/Encode_8b10b.v $(PWD)/SlowTransmitter2.sv $(PWD)/PayloadTransmitter.sv $(PWD)/SlowTransmitter2_tb.sv $(PWD)/crc_calc.sv
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=SlowTransmitter2_tb
# MODULE is the name of the Python test file:
MODULE=TestTransmitter


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps
# Tell it to trace the result
EXTRA_ARGS += --trace --trace-structs


include $(shell cocotb-config --makefiles)/Makefile.sim

