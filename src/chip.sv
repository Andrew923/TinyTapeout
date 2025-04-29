`default_nettype none

// Note: this is the I/O header I would use if we were
// to tapeout, but for FPGA usage look at ChipInterface.sv
module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    // signals only applicable on FPGA
    logic [7:0] led;
    logic [3:0] btn;
    
    ChipInterface internals(io_out[0],
                            led,
                            io_out[1],
                            io_out[2],
                            io_out[3],
                            io_in[0],
                            btn[0], btn[1],
                            btn[2], btn[3],
                            reset, clock);

endmodule
