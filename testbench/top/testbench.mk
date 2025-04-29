TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/../../*.v /mnt/c/Users/Andre/Downloads/18224/oss-cad-suite/share/yosys/ecp5/cells_bb.v
TOPLEVEL = ChipInterface
MODULE = test
SIM = verilator
EXTRA_ARGS += --trace --trace-structs -Wno-fatal
include $(shell cocotb-config --makefiles)/Makefile.sim
