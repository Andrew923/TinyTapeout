# Final Project Information

## Soft Body Physics Simulator

Based on accelerometer readings, simulates physics of a soft-body object and displays on WS2812 matrix

## Development Overview

The development for this Verilog occured in another repository at: https://github.com/Andrew923/18224-Project.
This repository only contains final .v files, which were created with sv2v. See other repository for details
such as the Python implementation the physics logic was based on.

## IO

These are not the actual signal names, but if we were to tapeout they would be something like this:

| Input/Output	| Description|																
|-------------|--------------------------------------------------|
| io_in[0]    | Serial Data Output (SDO) from IMU                |
| io_in[1]    | reset                                            |
| io_out[0]   | led_data to WS2812 LED matrix                    |
| io_out[1]   | Serial Data In (SDI) to IMU                      |
| io_out[2]   | Serial Port Clock (SPC) to IMU, 10 MHz           |
| io_out[3]   | Chip Select (CS) to IMU, enables SPI             |

## How to Test

Replace either IMU or LED matrix with software controlled script to
emulate SPI or WS2812 communication. Emulate simple force vectors in
all directions to ensure input is read correctly or take output and
visually display to make sure output logic is correct.

# 18-224/624 S25 Tapeout Template

1. All Verilog source files in `source_files` in `info.yaml`. The top level chip in `chip.sv` and name `my_chip`


2. Other details in `info.yaml`

3. Unchanged: `toplevel_chip.v`  `config.tcl` and `pin_order.cfg`

 # Final Project Submission Details 
  
1. Your design must synthesize at 30MHz but you can run it at any arbitrarily-slow frequency (including single-stepping the clock) on the manufactured chip. If your design must run at an exact frequency, it is safest to choose a lower frequency (i.e. 5MHz)

  
2. For your final project, we will ask you to submit some sort of testbench to verify your design. Include all relevant testing files inside the `testbench` repository


3. For your final project, we will ask you to submit documentation on how to run/test your design, as well as include your project proposal and progress reports. Include all these files inside the `docs` repository

  
4. Optionally, if you use any images in your documentation (diagrams, waveforms, etc) please include them in a separate `img` repository

5. Feel free to edit this file and include some basic information about your project (short description, inputs and outputs, diagrams, how to run, etc). An outline is provided below
