
#		$(PWD)/../../general/FIFO_CDC/registers.svh \
#		$(PWD)/../../general/FIFO_CDC/gray_to_binary.sv \
#		$(PWD)/../../general/FIFO_CDC/spill_register.sv \
#		$(PWD)/../../general/FIFO_CDC/spill_register_flushable.sv \
#		$(PWD)/../../general/FIFO_CDC/binary_to_gray.sv \
#		$(PWD)/../../general/FIFO_CDC/sync.sv \
#		$(PWD)/../../general/FIFO_CDC/cdc_fifo_gray.sv \



VERILOG_SOURCES = \
		$(PWD)/../../general/async_fifo/src/vlog/* \
		$(PWD)/SPI_RW.sv \
		$(PWD)/MRAM.sv \
		$(PWD)/crc_calc.sv \
		$(PWD)/Encode_8b10b.v \
		$(PWD)/data_frames.sv \
		$(PWD)/PayloadTransmitter.sv \
		$(PWD)/PulseIdGenerator.sv \
		$(PWD)/data_frames.sv
# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file:
TOPLEVEL=pulse_id_gen
# MODULE is the name of the Python test file:
MODULE=TestPulseIdGenerator


# use the Verilator for simulation
SIM=verilator
# set the timing precision (for performance reasons)
COCOTB_HDL_TIMEPRECISION = 100ps
# Tell it to trace the result
EXTRA_ARGS += --trace --trace-structs -I$(PWD)/../../general/FIFO_CDC/ -Wno-WIDTH


include $(shell cocotb-config --makefiles)/Makefile.sim

