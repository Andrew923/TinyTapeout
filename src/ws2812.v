`default_nettype none
module ws2812 (
	clock,
	reset,
	imu_data,
	matrix,
	o_out
);
	input wire clock;
	input wire reset;
	input wire [95:0] imu_data;
	input wire [255:0] matrix;
	output wire o_out;
	parameter CLK_FREQ = 20000000;
	parameter NUM_LEDS = 256;
	parameter NUM_FRAMES = 1;
	reg [255:0] old_matrix;
	reg [$clog2(NUM_FRAMES + 1):0] frame_idx;
	reg update;
	wire busy;
	reg [(NUM_LEDS * 24) - 1:0] data;
	wire in_bounds;
	wire done;
	function automatic [7:0] sv2v_cast_8;
		input reg [7:0] inp;
		sv2v_cast_8 = inp;
	endfunction
	always @(*) begin : sv2v_autoblock_1
		reg signed [31:0] start;
		for (start = 0; start < 256; start = start + 32)
			begin
				begin : sv2v_autoblock_2
					reg signed [31:0] led_idx;
					for (led_idx = start; led_idx < (start + 16); led_idx = led_idx + 1)
						data[((NUM_LEDS - 1) - (((start << 1) + 15) - led_idx)) * 24+:24] = {sv2v_cast_8((old_matrix[((led_idx >> 4) * 16) + (led_idx & 15)] ? 8'd4 + ((led_idx >> 6) & 3) : 8'd0)), sv2v_cast_8((old_matrix[((led_idx >> 4) * 16) + (led_idx & 15)] ? 8'd4 + ((led_idx >> 5) & 3) : 8'd0)), sv2v_cast_8((old_matrix[((led_idx >> 4) * 16) + (led_idx & 15)] ? 8'd4 + ((led_idx >> 4) & 3) : 8'd0))};
				end
				begin : sv2v_autoblock_3
					reg signed [31:0] led_idx;
					for (led_idx = start + 16; led_idx < (start + 32); led_idx = led_idx + 1)
						data[((NUM_LEDS - 1) - led_idx) * 24+:24] = {sv2v_cast_8((old_matrix[((led_idx >> 4) * 16) + (led_idx & 15)] ? 8'd4 + ((led_idx >> 6) & 3) : 8'd0)), sv2v_cast_8((old_matrix[((led_idx >> 4) * 16) + (led_idx & 15)] ? 8'd4 + ((led_idx >> 5) & 3) : 8'd0)), sv2v_cast_8((old_matrix[((led_idx >> 4) * 16) + (led_idx & 15)] ? 8'd4 + ((led_idx >> 4) & 3) : 8'd0))};
				end
			end
	end
	always @(posedge clock) begin
		update <= 0;
		if (reset || done) begin
			frame_idx <= 0;
			old_matrix <= matrix;
		end
		else if ((frame_idx < NUM_FRAMES) && !busy)
			update <= 1;
		if (update)
			frame_idx <= frame_idx + 1;
	end
	assign done = ((frame_idx >= NUM_FRAMES) && !busy) && !update;
	ws2812_inner #(
		.NUM_LEDS(NUM_LEDS),
		.CLK_FREQ(CLK_FREQ)
	) ws(
		.o_out(o_out),
		.busy(busy),
		.data(data),
		.update(update),
		.clock(clock),
		.reset(reset)
	);
endmodule
module ws2812_inner (
	o_out,
	busy,
	data,
	update,
	clock,
	reset
);
	parameter NUM_LEDS = 7;
	parameter CLK_FREQ = 10000000;
	output reg o_out;
	output wire busy;
	input wire [(NUM_LEDS * 24) - 1:0] data;
	input wire update;
	input wire clock;
	input wire reset;
	localparam T0H = $rtoi(CLK_FREQ / (1000000 / 0.4));
	localparam T1H = $rtoi(CLK_FREQ / (1000000 / 0.8));
	localparam T0L = $rtoi(CLK_FREQ / (1000000 / 0.85));
	localparam T1L = $rtoi(CLK_FREQ / (1000000 / 0.45));
	localparam LATCH_TIME = $rtoi(CLK_FREQ / 5000);
	localparam PULSE_WIDTH = $rtoi(CLK_FREQ / (1000000 / 1.25));
	reg [(NUM_LEDS * 24) - 1:0] data_int;
	reg [8:0] led_index = 0;
	reg [5:0] bit_index = 0;
	reg [6:0] current_bit_index = 0;
	reg [17:0] latch_ctr = 0;
	reg refresh = 0;
	assign busy = refresh;
	wire [23:0] cur_led_dat;
	wire cur_bit_dat;
	assign cur_led_dat = {data_int[(((NUM_LEDS - 1) - led_index) * 24) + 15-:8], data_int[(((NUM_LEDS - 1) - led_index) * 24) + 23-:8], data_int[(((NUM_LEDS - 1) - led_index) * 24) + 7-:8]};
	assign cur_bit_dat = cur_led_dat[23 - bit_index];
	always @(posedge clock) begin
		o_out <= 0;
		if (reset) begin
			led_index <= 0;
			bit_index <= 0;
			current_bit_index <= 0;
			latch_ctr <= 0;
			refresh <= 0;
		end
		else if (refresh) begin
			if (latch_ctr > 1) begin
				latch_ctr <= latch_ctr - 1;
				o_out <= 0;
			end
			else if (latch_ctr == 1) begin
				refresh <= 0;
				latch_ctr <= 0;
				led_index <= 0;
				bit_index <= 0;
				current_bit_index <= 0;
			end
			else begin
				current_bit_index <= current_bit_index + 1;
				if ((current_bit_index + 1) == PULSE_WIDTH) begin
					current_bit_index <= 0;
					bit_index <= bit_index + 1;
					if ((bit_index + 1) == 24) begin
						bit_index <= 0;
						if ((led_index + 1) == NUM_LEDS) begin
							led_index <= 0;
							latch_ctr <= LATCH_TIME;
						end
					end
					if ((bit_index + 1) == 24)
						led_index <= led_index + 1;
				end
				o_out <= current_bit_index < (cur_bit_dat ? T1H : T0H);
			end
		end
		else if (update) begin
			refresh <= 1;
			latch_ctr <= 0;
			led_index <= 0;
			bit_index <= 0;
			current_bit_index <= 0;
			data_int <= data;
		end
	end
endmodule
