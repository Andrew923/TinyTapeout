`default_nettype none
module my_chip (
	io_in,
	io_out,
	clock,
	reset
);
	input wire [11:0] io_in;
	output wire [11:0] io_out;
	input wire clock;
	input wire reset;
	wire [7:0] led;
	wire [3:0] btn;
	ChipInterface internals(
		.led_data(io_out[0]),
		.led(led),
		.SDI(io_out[1]),
		.SPC(io_out[2]),
		.CS(io_out[3]),
		.SDO(io_in[0]),
		.btn_left(btn[0]),
		.btn_right(btn[1]),
		.btn_up(btn[2]),
		.btn_down(btn[3]),
		.rst(reset),
		.clk(clock)
	);
endmodule
