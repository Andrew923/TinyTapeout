`default_nettype none
module spi (
	addr,
	wdata,
	read,
	clk,
	enable,
	reset,
	SDO,
	SPC,
	CS,
	SDI,
	rdata,
	done
);
	input wire [7:0] addr;
	input wire [7:0] wdata;
	input wire read;
	input wire clk;
	input wire enable;
	input wire reset;
	input wire SDO;
	output reg SPC;
	output reg CS;
	output reg SDI;
	output reg [7:0] rdata;
	output reg done;
	reg [5:0] curr_state;
	reg [5:0] next_state;
	always @(*) begin
		next_state = curr_state;
		case (curr_state)
			6'd0: next_state = (enable ? 6'd1 : 6'd0);
			6'd1: next_state = 6'd2;
			6'd2: next_state = 6'd3;
			6'd3: next_state = 6'd4;
			6'd4: next_state = 6'd5;
			6'd5: next_state = 6'd6;
			6'd6: next_state = 6'd7;
			6'd7: next_state = 6'd8;
			6'd8: next_state = 6'd9;
			6'd9: next_state = 6'd10;
			6'd10: next_state = 6'd11;
			6'd11: next_state = 6'd12;
			6'd12: next_state = 6'd13;
			6'd13: next_state = 6'd14;
			6'd14: next_state = 6'd15;
			6'd15: next_state = 6'd16;
			6'd16: next_state = 6'd17;
			6'd17: next_state = 6'd18;
			6'd18: next_state = 6'd19;
			6'd19: next_state = 6'd20;
			6'd20: next_state = 6'd21;
			6'd21: next_state = 6'd22;
			6'd22: next_state = 6'd23;
			6'd23: next_state = 6'd24;
			6'd24: next_state = 6'd25;
			6'd25: next_state = 6'd26;
			6'd26: next_state = 6'd27;
			6'd27: next_state = 6'd28;
			6'd28: next_state = 6'd29;
			6'd29: next_state = 6'd30;
			6'd30: next_state = 6'd31;
			6'd31: next_state = 6'd32;
			6'd32: next_state = 6'd33;
			6'd33: next_state = 6'd34;
			6'd34: next_state = 6'd0;
		endcase
	end
	always @(*) begin
		CS = (curr_state == 6'd0) || (curr_state == 6'd34);
		done = curr_state == 6'd34;
	end
	always @(posedge clk) begin
		case (curr_state)
			6'd0: rdata <= 8'd0;
			6'd18: rdata[7] <= SDO;
			6'd20: rdata[6] <= SDO;
			6'd22: rdata[5] <= SDO;
			6'd24: rdata[4] <= SDO;
			6'd26: rdata[3] <= SDO;
			6'd28: rdata[2] <= SDO;
			6'd30: rdata[1] <= SDO;
			6'd32: rdata[0] <= SDO;
		endcase
		case (curr_state)
			6'd0: SPC <= 1'b1;
			6'd1: SPC <= 1'b0;
			6'd2: SPC <= 1'b1;
			6'd3: SPC <= 1'b0;
			6'd4: SPC <= 1'b1;
			6'd5: SPC <= 1'b0;
			6'd6: SPC <= 1'b1;
			6'd7: SPC <= 1'b0;
			6'd8: SPC <= 1'b1;
			6'd9: SPC <= 1'b0;
			6'd10: SPC <= 1'b1;
			6'd11: SPC <= 1'b0;
			6'd12: SPC <= 1'b1;
			6'd13: SPC <= 1'b0;
			6'd14: SPC <= 1'b1;
			6'd15: SPC <= 1'b0;
			6'd16: SPC <= 1'b1;
			6'd17: SPC <= 1'b0;
			6'd18: SPC <= 1'b1;
			6'd19: SPC <= 1'b0;
			6'd20: SPC <= 1'b1;
			6'd21: SPC <= 1'b0;
			6'd22: SPC <= 1'b1;
			6'd23: SPC <= 1'b0;
			6'd24: SPC <= 1'b1;
			6'd25: SPC <= 1'b0;
			6'd26: SPC <= 1'b1;
			6'd27: SPC <= 1'b0;
			6'd28: SPC <= 1'b1;
			6'd29: SPC <= 1'b0;
			6'd30: SPC <= 1'b1;
			6'd31: SPC <= 1'b0;
			6'd32: SPC <= 1'b1;
			6'd33: SPC <= 1'b1;
			6'd34: SPC <= 1'b1;
		endcase
		case (curr_state)
			6'd1: SDI <= read;
			6'd2: SDI <= read;
			6'd3: SDI <= addr[6];
			6'd4: SDI <= addr[6];
			6'd5: SDI <= addr[5];
			6'd6: SDI <= addr[5];
			6'd7: SDI <= addr[4];
			6'd8: SDI <= addr[4];
			6'd9: SDI <= addr[3];
			6'd10: SDI <= addr[3];
			6'd11: SDI <= addr[2];
			6'd12: SDI <= addr[2];
			6'd13: SDI <= addr[1];
			6'd14: SDI <= addr[1];
			6'd15: SDI <= addr[0];
			6'd16: SDI <= addr[0];
			6'd17: SDI <= (read ? 1'b0 : wdata[7]);
			6'd18: SDI <= (read ? 1'b0 : wdata[7]);
			6'd19: SDI <= (read ? 1'b0 : wdata[6]);
			6'd20: SDI <= (read ? 1'b0 : wdata[6]);
			6'd21: SDI <= (read ? 1'b0 : wdata[5]);
			6'd22: SDI <= (read ? 1'b0 : wdata[5]);
			6'd23: SDI <= (read ? 1'b0 : wdata[4]);
			6'd24: SDI <= (read ? 1'b0 : wdata[4]);
			6'd25: SDI <= (read ? 1'b0 : wdata[3]);
			6'd26: SDI <= (read ? 1'b0 : wdata[3]);
			6'd27: SDI <= (read ? 1'b0 : wdata[2]);
			6'd28: SDI <= (read ? 1'b0 : wdata[2]);
			6'd29: SDI <= (read ? 1'b0 : wdata[1]);
			6'd30: SDI <= (read ? 1'b0 : wdata[1]);
			6'd31: SDI <= (read ? 1'b0 : wdata[0]);
			6'd32: SDI <= (read ? 1'b0 : wdata[0]);
		endcase
	end
	always @(posedge clk)
		if (reset)
			curr_state <= 6'd0;
		else
			curr_state <= next_state;
endmodule
module spi_multi (
	addr,
	clk,
	enable,
	reset,
	SDO,
	SPC,
	CS,
	SDI,
	rdata,
	done
);
	parameter BYTES = 12;
	input wire [7:0] addr;
	input wire clk;
	input wire enable;
	input wire reset;
	input wire SDO;
	output reg SPC;
	output reg CS;
	output reg SDI;
	output reg [(8 * BYTES) - 1:0] rdata;
	output reg done;
	reg [5:0] curr_state;
	reg [5:0] next_state;
	reg [$clog2(BYTES + 1):0] byte_idx;
	always @(*) begin
		next_state = curr_state;
		case (curr_state)
			6'd0: next_state = (enable ? 6'd1 : 6'd0);
			6'd1: next_state = 6'd2;
			6'd2: next_state = 6'd3;
			6'd3: next_state = 6'd4;
			6'd4: next_state = 6'd5;
			6'd5: next_state = 6'd6;
			6'd6: next_state = 6'd7;
			6'd7: next_state = 6'd8;
			6'd8: next_state = 6'd9;
			6'd9: next_state = 6'd10;
			6'd10: next_state = 6'd11;
			6'd11: next_state = 6'd12;
			6'd12: next_state = 6'd13;
			6'd13: next_state = 6'd14;
			6'd14: next_state = 6'd15;
			6'd15: next_state = 6'd16;
			6'd16: next_state = 6'd17;
			6'd17: next_state = 6'd18;
			6'd18: next_state = 6'd19;
			6'd19: next_state = 6'd20;
			6'd20: next_state = 6'd21;
			6'd21: next_state = 6'd22;
			6'd22: next_state = 6'd23;
			6'd23: next_state = 6'd24;
			6'd24: next_state = 6'd25;
			6'd25: next_state = 6'd26;
			6'd26: next_state = 6'd27;
			6'd27: next_state = 6'd28;
			6'd28: next_state = 6'd29;
			6'd29: next_state = 6'd30;
			6'd30: next_state = 6'd31;
			6'd31: next_state = 6'd32;
			6'd32: next_state = ((byte_idx + 1) < BYTES ? 6'd17 : 6'd33);
			6'd33: next_state = 6'd34;
			6'd34: next_state = 6'd0;
		endcase
	end
	always @(*) begin
		CS = (curr_state == 6'd0) || (curr_state == 6'd34);
		done = curr_state == 6'd34;
	end
	always @(posedge clk) begin
		case (curr_state)
			6'd0: rdata <= 96'd0;
			6'd18: rdata[(byte_idx << 3) + 7] <= SDO;
			6'd20: rdata[(byte_idx << 3) + 6] <= SDO;
			6'd22: rdata[(byte_idx << 3) + 5] <= SDO;
			6'd24: rdata[(byte_idx << 3) + 4] <= SDO;
			6'd26: rdata[(byte_idx << 3) + 3] <= SDO;
			6'd28: rdata[(byte_idx << 3) + 2] <= SDO;
			6'd30: rdata[(byte_idx << 3) + 1] <= SDO;
			6'd32: rdata[(byte_idx << 3) + 0] <= SDO;
		endcase
		case (curr_state)
			6'd0: SPC <= 1'b1;
			6'd1: SPC <= 1'b0;
			6'd2: SPC <= 1'b1;
			6'd3: SPC <= 1'b0;
			6'd4: SPC <= 1'b1;
			6'd5: SPC <= 1'b0;
			6'd6: SPC <= 1'b1;
			6'd7: SPC <= 1'b0;
			6'd8: SPC <= 1'b1;
			6'd9: SPC <= 1'b0;
			6'd10: SPC <= 1'b1;
			6'd11: SPC <= 1'b0;
			6'd12: SPC <= 1'b1;
			6'd13: SPC <= 1'b0;
			6'd14: SPC <= 1'b1;
			6'd15: SPC <= 1'b0;
			6'd16: SPC <= 1'b1;
			6'd17: SPC <= 1'b0;
			6'd18: SPC <= 1'b1;
			6'd19: SPC <= 1'b0;
			6'd20: SPC <= 1'b1;
			6'd21: SPC <= 1'b0;
			6'd22: SPC <= 1'b1;
			6'd23: SPC <= 1'b0;
			6'd24: SPC <= 1'b1;
			6'd25: SPC <= 1'b0;
			6'd26: SPC <= 1'b1;
			6'd27: SPC <= 1'b0;
			6'd28: SPC <= 1'b1;
			6'd29: SPC <= 1'b0;
			6'd30: SPC <= 1'b1;
			6'd31: SPC <= 1'b0;
			6'd32: SPC <= 1'b1;
			6'd33: SPC <= 1'b1;
			6'd34: SPC <= 1'b1;
		endcase
		case (curr_state)
			6'd1: SDI <= 1'b1;
			6'd2: SDI <= 1'b1;
			6'd3: SDI <= addr[6];
			6'd4: SDI <= addr[6];
			6'd5: SDI <= addr[5];
			6'd6: SDI <= addr[5];
			6'd7: SDI <= addr[4];
			6'd8: SDI <= addr[4];
			6'd9: SDI <= addr[3];
			6'd10: SDI <= addr[3];
			6'd11: SDI <= addr[2];
			6'd12: SDI <= addr[2];
			6'd13: SDI <= addr[1];
			6'd14: SDI <= addr[1];
			6'd15: SDI <= addr[0];
			6'd16: SDI <= addr[0];
		endcase
	end
	always @(posedge clk)
		if (reset)
			curr_state <= 6'd0;
		else begin
			curr_state <= next_state;
			if (next_state == 6'd16)
				byte_idx <= 0;
			if ((curr_state != next_state) && (curr_state == 6'd32))
				byte_idx <= byte_idx + 1;
		end
endmodule
