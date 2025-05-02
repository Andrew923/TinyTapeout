`default_nettype none
module particle (
	x0,
	y0,
	vx0,
	vy0,
	x1,
	y1,
	vx1,
	vy1,
	x2,
	y2,
	vx2,
	vy2,
	data,
	clk,
	reset,
	x,
	y,
	vel_x,
	vel_y
);
	parameter signed [15:0] MASS = 8;
	parameter signed [15:0] M0 = 8;
	parameter signed [15:0] M1 = 8;
	parameter signed [15:0] M2 = 8;
	parameter signed [15:0] INIT_X = 128;
	parameter signed [15:0] INIT_Y = 128;
	parameter signed [15:0] REST0 = 64;
	parameter signed [15:0] REST1 = 64;
	parameter signed [15:0] REST2 = 64;
	parameter signed [15:0] PHASE_OFFSET = 0;
	input wire signed [15:0] x0;
	input wire signed [15:0] y0;
	input wire signed [15:0] vx0;
	input wire signed [15:0] vy0;
	input wire signed [15:0] x1;
	input wire signed [15:0] y1;
	input wire signed [15:0] vx1;
	input wire signed [15:0] vy1;
	input wire signed [15:0] x2;
	input wire signed [15:0] y2;
	input wire signed [15:0] vx2;
	input wire signed [15:0] vy2;
	input data_t data;
	input wire clk;
	input wire reset;
	output reg signed [15:0] x;
	output reg signed [15:0] y;
	output reg signed [15:0] vel_x;
	output reg signed [15:0] vel_y;
	parameter WIDTH = 256;
	reg signed [15:0] px;
	reg signed [15:0] py;
	reg signed [15:0] px_old;
	reg signed [15:0] py_old;
	reg signed [15:0] vx;
	reg signed [15:0] vy;
	reg signed [15:0] ax;
	reg signed [15:0] ay;
	reg signed [15:0] force_x;
	reg signed [15:0] force_y;
	wire signed [15:0] imu_x;
	wire signed [15:0] imu_y;
	reg signed [15:0] dx0;
	reg signed [15:0] dy0;
	reg signed [15:0] dx1;
	reg signed [15:0] dy1;
	reg signed [15:0] dx2;
	reg signed [15:0] dy2;
	reg signed [15:0] dx0_2;
	reg signed [15:0] dy0_2;
	reg signed [15:0] dx1_2;
	reg signed [15:0] dy1_2;
	reg signed [15:0] dx2_2;
	reg signed [15:0] dy2_2;
	reg signed [15:0] d0;
	reg signed [15:0] d1;
	reg signed [15:0] d2;
	reg signed [15:0] displace0;
	reg signed [15:0] displace1;
	reg signed [15:0] displace2;
	reg signed [15:0] rel_vel_x0;
	reg signed [15:0] rel_vel_x1;
	reg signed [15:0] rel_vel_x2;
	reg signed [15:0] rel_vel_y0;
	reg signed [15:0] rel_vel_y1;
	reg signed [15:0] rel_vel_y2;
	reg signed [15:0] dampx0;
	reg signed [15:0] dampx1;
	reg signed [15:0] dampx2;
	reg signed [15:0] dampy0;
	reg signed [15:0] dampy1;
	reg signed [15:0] dampy2;
	reg signed [15:0] damp0;
	reg signed [15:0] damp1;
	reg signed [15:0] damp2;
	reg signed [15:0] multa;
	reg signed [15:0] multb;
	parameter TOTAL_CYCLES = 300000;
	wire [$clog2(TOTAL_CYCLES + 1):0] idx;
	wire clear;
	Counter #($clog2(TOTAL_CYCLES + 1) + 1) counter(
		clk,
		clear,
		idx
	);
	assign clear = reset;
	always @(*) begin
		x = px;
		y = py;
		vel_x = vx;
		vel_y = vy;
	end
	always @(*)
		case (idx)
			PHASE_OFFSET + 11: begin
				multa = px - x0;
				multb = px - x0;
			end
			PHASE_OFFSET + 12: begin
				multa = py - y0;
				multb = py - y0;
			end
			PHASE_OFFSET + 17: begin
				multa = rel_vel_x0;
				multb = dx0;
			end
			PHASE_OFFSET + 18: begin
				multa = rel_vel_y0;
				multb = dy0;
			end
			PHASE_OFFSET + 20: begin
				multa = (displace0 >>> (6 - $clog2(M0))) + damp0;
				multb = dx0 >>> 2;
			end
			PHASE_OFFSET + 21: begin
				multa = (displace0 >>> (6 - $clog2(M0))) + damp0;
				multb = dy0 >>> 2;
			end
			PHASE_OFFSET + 24: begin
				multa = px - x1;
				multb = px - x1;
			end
			PHASE_OFFSET + 25: begin
				multa = py - y1;
				multb = py - y1;
			end
			PHASE_OFFSET + 30: begin
				multa = rel_vel_x1;
				multb = dx1;
			end
			PHASE_OFFSET + 31: begin
				multa = rel_vel_y1;
				multb = dy1;
			end
			PHASE_OFFSET + 37: begin
				multa = (displace1 >>> (6 - $clog2(M1))) + damp1;
				multb = dx1 >>> 2;
			end
			PHASE_OFFSET + 38: begin
				multa = (displace1 >>> (6 - $clog2(M1))) + damp1;
				multb = dy1 >>> 2;
			end
			PHASE_OFFSET + 35: begin
				multa = px - x2;
				multb = px - x2;
			end
			PHASE_OFFSET + 36: begin
				multa = py - y2;
				multb = py - y2;
			end
			PHASE_OFFSET + 43: begin
				multa = rel_vel_x2;
				multb = dx2;
			end
			PHASE_OFFSET + 44: begin
				multa = rel_vel_y2;
				multb = dy2;
			end
			PHASE_OFFSET + 46: begin
				multa = (displace2 >>> (6 - $clog2(M2))) + damp2;
				multb = dx2 >>> 2;
			end
			PHASE_OFFSET + 47: begin
				multa = (displace2 >>> (6 - $clog2(M2))) + damp2;
				multb = dy2 >>> 2;
			end
			default: begin
				multa = 0;
				multb = 0;
			end
		endcase
	always @(posedge clk)
		if (reset) begin
			px <= INIT_X;
			py <= INIT_Y;
			px_old <= INIT_X;
			py_old <= INIT_Y;
			vx <= 0;
			vy <= 0;
			ax <= 0;
			ay <= 0;
		end
		else
			case (idx)
				PHASE_OFFSET + 0: begin
					force_x <= imu_x;
					force_y <= -imu_y;
				end
				PHASE_OFFSET + 1: px <= ((px << 1) - px_old) + (ax >>> 2);
				PHASE_OFFSET + 2: py <= ((py << 1) - py_old) + (ay >>> 2);
				PHASE_OFFSET + 3: ax <= 0;
				PHASE_OFFSET + 4: ay <= 0;
				PHASE_OFFSET + 5: vx <= (px - px_old) >>> 1;
				PHASE_OFFSET + 6: vy <= (py - py_old) >>> 1;
				PHASE_OFFSET + 7: px_old <= px;
				PHASE_OFFSET + 8: py_old <= py;
				PHASE_OFFSET + 9: dx0 <= px - x0;
				PHASE_OFFSET + 10: dy0 <= py - y0;
				PHASE_OFFSET + 11: dx0_2 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 12: dy0_2 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 13: d0 <= dx0_2 + dy0_2;
				PHASE_OFFSET + 14:
					if (d0 > 0)
						displace0 <= REST0 - d0;
				PHASE_OFFSET + 15:
					if (d0 > 0)
						rel_vel_x0 <= vx - vx0;
				PHASE_OFFSET + 16:
					if (d0 > 0)
						rel_vel_y0 <= vy - vy0;
				PHASE_OFFSET + 17:
					if (d0 > 0)
						dampx0 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 18:
					if (d0 > 0)
						dampy0 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 19:
					if (d0 > 0)
						damp0 <= (dampx0 + dampy0) >>> 2;
				PHASE_OFFSET + 20:
					if (d0 > 0)
						ax <= ax + ((multa * multb) >>> 4);
				PHASE_OFFSET + 21:
					if (d0 > 0)
						ay <= ay + ((multa * multb) >>> 4);
				PHASE_OFFSET + 22: dx1 <= px - x1;
				PHASE_OFFSET + 23: dy1 <= py - y1;
				PHASE_OFFSET + 24: dx1_2 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 25: dy1_2 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 26: d1 <= dx1_2 + dy1_2;
				PHASE_OFFSET + 27:
					if (d1 > 0)
						displace1 <= d1 - REST1;
				PHASE_OFFSET + 28:
					if (d1 > 0)
						rel_vel_x1 <= vx - vx1;
				PHASE_OFFSET + 29:
					if (d1 > 0)
						rel_vel_y1 <= vy - vy1;
				PHASE_OFFSET + 30:
					if (d1 > 0)
						dampx1 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 31:
					if (d1 > 0)
						dampy1 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 32:
					if (d1 > 0)
						damp1 <= (dampx1 + dampy1) >>> 2;
				PHASE_OFFSET + 33:
					if (d1 > 0)
						ax <= ax + ((multa * multb) >>> 4);
				PHASE_OFFSET + 34:
					if (d1 > 0)
						ay <= ay + ((multa * multb) >>> 4);
				PHASE_OFFSET + 35: dx2 <= px - x2;
				PHASE_OFFSET + 36: dy2 <= py - y2;
				PHASE_OFFSET + 37: dx2_2 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 38: dy2_2 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 39: d2 <= dx2_2 + dy2_2;
				PHASE_OFFSET + 40:
					if (d2 > 0)
						displace2 <= d2 - REST2;
				PHASE_OFFSET + 41:
					if (d2 > 0)
						rel_vel_x2 <= vx - vx2;
				PHASE_OFFSET + 42:
					if (d2 > 0)
						rel_vel_y2 <= vy - vy2;
				PHASE_OFFSET + 43:
					if (d2 > 0)
						dampx2 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 44:
					if (d2 > 0)
						dampy2 <= (multa * multb) >>> 4;
				PHASE_OFFSET + 45:
					if (d2 > 0)
						damp2 <= (dampx2 + dampy2) >>> 2;
				PHASE_OFFSET + 46:
					if (d2 > 0)
						ax <= ax + ((multa * multb) >>> 4);
				PHASE_OFFSET + 47:
					if (d2 > 0)
						ay <= ay + ((multa * multb) >>> 4);
				PHASE_OFFSET + 48:
					if (px < 0) begin
						px <= 0;
						vx <= -(vx >>> 1);
					end
				PHASE_OFFSET + 49:
					if (px >= WIDTH) begin
						px <= WIDTH - 1;
						vx <= -(vx >>> 1);
					end
				PHASE_OFFSET + 50:
					if (py < 0) begin
						py <= 0;
						vy <= -(vx >>> 1);
					end
				PHASE_OFFSET + 51:
					if (py >= WIDTH) begin
						py <= WIDTH - 1;
						vy <= -(vx >>> 1);
					end
			endcase
endmodule
module center (
	x0,
	y0,
	vx0,
	vy0,
	x1,
	y1,
	vx1,
	vy1,
	x2,
	y2,
	vx2,
	vy2,
	data,
	clk,
	reset,
	x,
	y,
	vel_x,
	vel_y
);
	parameter signed [15:0] MASS = 16;
	parameter signed [15:0] INIT_X = 128;
	parameter signed [15:0] INIT_Y = 128;
	parameter signed [15:0] PHASE_OFFSET = 0;
	input wire signed [15:0] x0;
	input wire signed [15:0] y0;
	input wire signed [15:0] vx0;
	input wire signed [15:0] vy0;
	input wire signed [15:0] x1;
	input wire signed [15:0] y1;
	input wire signed [15:0] vx1;
	input wire signed [15:0] vy1;
	input wire signed [15:0] x2;
	input wire signed [15:0] y2;
	input wire signed [15:0] vx2;
	input wire signed [15:0] vy2;
	input data_t data;
	input wire clk;
	input wire reset;
	output reg signed [15:0] x;
	output reg signed [15:0] y;
	output reg signed [15:0] vel_x;
	output reg signed [15:0] vel_y;
	parameter WIDTH = 256;
	reg signed [15:0] px;
	reg signed [15:0] py;
	reg signed [15:0] px_old;
	reg signed [15:0] py_old;
	reg signed [15:0] vx;
	reg signed [15:0] vy;
	reg signed [15:0] ax;
	reg signed [15:0] ay;
	reg signed [15:0] force_x;
	reg signed [15:0] force_y;
	reg signed [15:0] imu_x;
	reg signed [15:0] imu_y;
	parameter TOTAL_CYCLES = 300000;
	wire [$clog2(TOTAL_CYCLES + 1):0] idx;
	wire clear;
	Counter #($clog2(TOTAL_CYCLES + 1) + 1) counter(
		clk,
		clear,
		idx
	);
	assign clear = reset;
	function automatic signed [15:0] sv2v_cast_16_signed;
		input reg signed [15:0] inp;
		sv2v_cast_16_signed = inp;
	endfunction
	always @(*) begin
		x = px;
		y = py;
		vel_x = vx;
		vel_y = vy;
		imu_x = sv2v_cast_16_signed(data.x);
		imu_y = sv2v_cast_16_signed(data.y);
	end
	always @(posedge clk)
		if (reset) begin
			px <= INIT_X;
			py <= INIT_Y;
			px_old <= INIT_X;
			py_old <= INIT_Y;
			vx <= 0;
			vy <= 0;
			ax <= 0;
			ay <= 0;
		end
		else
			case (idx)
				PHASE_OFFSET + 0: begin
					force_x <= imu_x;
					force_y <= -imu_y;
				end
				PHASE_OFFSET + 1: ax <= force_x >>> 8;
				PHASE_OFFSET + 2: ay <= force_y >>> 8;
				PHASE_OFFSET + 3: px <= ((px << 1) - px_old) + ax;
				PHASE_OFFSET + 4: py <= ((py << 1) - py_old) + ay;
				PHASE_OFFSET + 5: vx <= (px - px_old) >>> 1;
				PHASE_OFFSET + 6: vy <= (py - py_old) >>> 1;
				PHASE_OFFSET + 7: px_old <= px;
				PHASE_OFFSET + 8: py_old <= py;
				PHASE_OFFSET + 48:
					if (px < 0) begin
						px <= 0;
						vx <= -(vx >>> 1);
					end
				PHASE_OFFSET + 49:
					if (px >= WIDTH) begin
						px <= WIDTH - 1;
						vx <= -(vx >>> 1);
					end
				PHASE_OFFSET + 50:
					if (py < 0) begin
						py <= 0;
						vy <= -(vx >>> 1);
					end
				PHASE_OFFSET + 51:
					if (py >= WIDTH) begin
						py <= WIDTH - 1;
						vy <= -(vx >>> 1);
					end
			endcase
endmodule
