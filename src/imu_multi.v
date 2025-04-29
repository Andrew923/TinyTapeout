`default_nettype none
module imu_multi (
	reset,
	SDO,
	clk,
	SPC,
	CS,
	SDI,
	curr_data
);
	input wire reset;
	input wire SDO;
	input wire clk;
	output reg SPC;
	output reg CS;
	output reg SDI;
	output reg [95:0] curr_data;
	reg [4:0] curr_state;
	reg [4:0] next_state;
	reg [95:0] next_data;
	reg [7:0] addr;
	reg [7:0] wdata;
	wire [7:0] rdata_old;
	wire done_single;
	wire done_multi;
	reg enable_single;
	reg enable_multi;
	wire SPC_single;
	wire SPC_multi;
	wire CS_single;
	wire CS_multi;
	wire SDI_single;
	wire SDI_multi;
	spi spi_internal(
		.addr(addr),
		.wdata(wdata),
		.read(1'b0),
		.clk(clk),
		.enable(enable_single),
		.reset(reset),
		.SDO(SDO),
		.SPC(SPC_single),
		.CS(CS_single),
		.SDI(SDI_single),
		.rdata(rdata_old),
		.done(done_single)
	);
	wire [95:0] rdata;
	spi_multi #(.BYTES(12)) spi_reader(
		.addr(addr),
		.clk(clk),
		.enable(enable_multi),
		.reset(reset),
		.SDO(SDO),
		.SPC(SPC_multi),
		.CS(CS_multi),
		.SDI(SDI_multi),
		.rdata(rdata),
		.done(done_multi)
	);
	always @(*)
		if (curr_state == 5'd6) begin
			SPC = SPC_multi;
			CS = CS_multi;
			SDI = SDI_multi;
		end
		else begin
			SPC = SPC_single;
			CS = CS_single;
			SDI = SDI_single;
		end
	wire next_enable_single;
	wire next_enable_multi;
	assign next_enable_single = (curr_state != next_state) && ((((next_state == 5'd1) || (next_state == 5'd2)) || (next_state == 5'd3)) || (next_state == 5'd4));
	assign next_enable_multi = (curr_state != next_state) && (next_state == 5'd6);
	always @(posedge clk) begin
		enable_single <= next_enable_single;
		enable_multi <= next_enable_multi;
		case (curr_state)
			5'd1: addr <= 8'h18;
			5'd2: addr <= 8'h13;
			5'd3: addr <= 8'h11;
			5'd4: addr <= 8'h10;
			5'd6: addr <= 8'h22;
		endcase
		case (curr_state)
			5'd1: wdata <= 8'b11100010;
			5'd2: wdata <= 8'b00000100;
			5'd3: wdata <= 8'b01100000;
			5'd4: wdata <= 8'b01100000;
		endcase
	end
	function automatic signed [15:0] sv2v_cast_16_signed;
		input reg signed [15:0] inp;
		sv2v_cast_16_signed = inp;
	endfunction
	always @(posedge clk)
		case (curr_state)
			5'd5: next_data <= 96'd0;
			5'd6: next_data <= {sv2v_cast_16_signed({rdata[15:8], rdata[7:0]}), sv2v_cast_16_signed({rdata[31:24], rdata[23:16]}), sv2v_cast_16_signed({rdata[47:40], rdata[39:32]}), sv2v_cast_16_signed({rdata[63:56], rdata[55:48]}), sv2v_cast_16_signed({rdata[79:72], rdata[71:64]}), sv2v_cast_16_signed({rdata[95:88], rdata[87:80]})};
		endcase
	parameter WAIT_CYCLES = 4000000;
	wire [$clog2(WAIT_CYCLES + 1):0] wait_idx;
	wire clear;
	Counter #(.WIDTH($clog2(WAIT_CYCLES + 1) + 1)) wait_time(
		.clock(clk),
		.clear(clear),
		.Q(wait_idx)
	);
	assign clear = (curr_state == 5'd7) || (curr_state == 5'd4);
	parameter STATE_DELAY = 1000;
	wire [$clog2(STATE_DELAY + 1):0] delay;
	wire clear2;
	Counter #(.WIDTH($clog2(STATE_DELAY + 1) + 1)) delay_time(
		.clock(clk),
		.clear(clear2),
		.Q(delay)
	);
	edge_det done_edge(
		.signal(done_single),
		.clk(clk),
		.edge_seen(clear2)
	);
	always @(*) begin
		next_state = curr_state;
		case (curr_state)
			5'd0: next_state = (wait_idx == 700000 ? 5'd1 : 5'd0);
			5'd1: next_state = (delay == STATE_DELAY ? 5'd2 : 5'd1);
			5'd2: next_state = (delay == STATE_DELAY ? 5'd3 : 5'd2);
			5'd3: next_state = (delay == STATE_DELAY ? 5'd4 : 5'd3);
			5'd4: next_state = (delay == STATE_DELAY ? 5'd5 : 5'd4);
			5'd5: next_state = (wait_idx == WAIT_CYCLES ? 5'd6 : 5'd5);
			5'd6: next_state = (done_multi ? 5'd7 : 5'd6);
			5'd7: next_state = 5'd5;
		endcase
	end
	always @(posedge clk)
		if (reset) begin
			curr_state <= 5'd0;
			curr_data <= 96'd0;
		end
		else begin
			curr_state <= next_state;
			if (next_state == 5'd7)
				curr_data <= next_data;
		end
endmodule
