VERILOG_SOURCES =  $(PWD)/../../protocol/data_frames.sv \
    $(PWD)/../../PayloadTransmitter/PayloadTransmitter.sv \
    $(PWD)/../../CRC/crc_calc.sv \
    $(PWD)/../Transmitter2/SlowTransmitter2.sv \
    $(PWD)/Encode_8b10b.v \
	$(PWD)/../Receiver/CDR_10b_8b.sv \
	$(PWD)/../Receiver/AlexanderDetectorSync.sv \
	$(PWD)/Decode_8b10b.v  \
	$(PWD)/AllConnected.sv \
	$(PWD)/../Transmitter2/fifo_v3.sv
	

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=AllConnected
# MODULE is the name of the Python test file:
MODULE=TestTogether


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps
# Tell it to trace the result
EXTRA_ARGS += --trace --trace-structs


include $(shell cocotb-config --makefiles)/Makefile.sim

