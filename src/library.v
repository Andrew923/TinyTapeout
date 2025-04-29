`default_nettype none
module Counter (
	clock,
	clear,
	Q
);
	parameter WIDTH = 4;
	input wire clock;
	input wire clear;
	output reg [WIDTH - 1:0] Q;
	always @(posedge clock)
		if (clear)
			Q <= 1'sb0;
		else
			Q <= Q + 1;
endmodule
module Counter_neg (
	clock,
	clear,
	Q
);
	parameter WIDTH = 4;
	input wire clock;
	input wire clear;
	output reg [WIDTH - 1:0] Q;
	always @(negedge clock)
		if (clear)
			Q <= 1'sb0;
		else
			Q <= Q + 1;
endmodule
module Counter_async (
	clock,
	clear,
	Q
);
	parameter WIDTH = 4;
	input wire clock;
	input wire clear;
	output reg [WIDTH - 1:0] Q;
	always @(posedge clear) Q <= 1'sb0;
	always @(posedge clock) Q <= Q + 1;
endmodule
module edge_det (
	signal,
	clk,
	edge_seen
);
	input wire signal;
	input wire clk;
	output wire edge_seen;
	reg old_signal;
	always @(posedge clk) old_signal <= signal;
	assign edge_seen = ~old_signal & signal;
endmodule
module radius_check (
	x,
	y,
	x1,
	y1,
	valid
);
	parameter [0:0] ON_0 = 1;
	parameter [0:0] ON_30 = 0;
	parameter [0:0] ON_60 = 0;
	parameter [0:0] ON_90 = 1;
	parameter [0:0] ON_120 = 0;
	parameter [0:0] ON_150 = 0;
	parameter [0:0] ON_180 = 1;
	parameter [0:0] ON_210 = 0;
	parameter [0:0] ON_240 = 0;
	parameter [0:0] ON_270 = 1;
	parameter [0:0] ON_300 = 0;
	parameter [0:0] ON_330 = 0;
	input wire signed [15:0] x;
	input wire signed [15:0] y;
	input wire signed [15:0] x1;
	input wire signed [15:0] y1;
	output reg valid;
	reg signed [15:0] dx;
	reg signed [15:0] dy;
	always @(*) begin
		dx = x - x1;
		dy = y - y1;
		valid = ((((((((((((((((((((((dx == 0) && (dy == -2)) && ON_270) || ((dx == 0) && (dy == -1))) || ((dx == 0) && (dy == 0))) || ((dx == 0) && (dy == 1))) || (((dx == 0) && (dy == 2)) && ON_90)) || ((dx == 1) && (dy == -1))) || ((dx == 1) && (dy == 0))) || ((dx == 1) && (dy == 1))) || ((dx == -1) && (dy == -1))) || ((dx == -1) && (dy == 0))) || ((dx == -1) && (dy == 1))) || (((dx == 2) && (dy == 0)) && ON_0)) || (((dx == -2) && (dy == 0)) && ON_180)) || (((dx == 2) && (dy == 1)) && ON_30)) || (((dx == 1) && (dy == 2)) && ON_60)) || (((dx == -1) && (dy == 2)) && ON_120)) || (((dx == -2) && (dy == 1)) && ON_150)) || (((dx == -2) && (dy == -1)) && ON_210)) || (((dx == -1) && (dy == -2)) && ON_240)) || (((dx == 1) && (dy == -2)) && ON_300)) || (((dx == 2) && (dy == -1)) && ON_330);
	end
endmodule
