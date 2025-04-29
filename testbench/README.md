# Testing

Testing was mostly done on FPGA, but there are some tests using
CocoTB to look at specific simulation parameters/waveforms.

## Overview

Tests are split into directories depending on module, with a Makefile
in each directory. The top tests are for general integration tests
to look at particle positions as well as what the matrix display should
look like. The physics test is just used for generating the waveform
so that you can see specific parameter values. The spi tests are also
mainly for generating the waveform to make sure it visually matches
the IMU's datasheet.

## Usage
To run, use the following command which should generate Verilog files
and run the Makefile. Note that the testbench files currently have
paths for my personal machine, which may need to be modified.

sv2v --write=adjacent ../../src/*.sv && make -Bf testbench.mk
