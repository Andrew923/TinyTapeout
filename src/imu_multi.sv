`default_nettype none
// Overview:
// Initial states begin with configuration
// which requires SPI writes. Then, we
// continuously read fields in a loop.

// Struct to hold all relevant IMU data
// Addresses of data:
// - OUTX_L_G 0x22 1
// - OUTX_H_G 0x23 2
// - OUTY_L_G 0x24 3
// - OUTY_H_G 0x25 4
// - OUTZ_L_G 0x26 5
// - OUTZ_H_G 0x27 6
// - OUTX_L_A 0x28 7
// - OUTX_H_A 0x29 8
// - OUTY_L_A 0x2A 9
// - OUTY_H_A 0x2B 10
// - OUTZ_L_A 0x2C 11
// - OUTZ_H_A 0x2D 12
typedef struct packed {
  logic signed [15:0] pitch; // OUTX_{L, H}_G
  logic signed [15:0] roll; // OUTY_{L, H}_G
  logic signed [15:0] yaw; // OUTZ_{L, H}_G
  logic signed [15:0] x; // OUTX_{L, H}_A
  logic signed [15:0] y; // OUTY_{L, H}_A
  logic signed [15:0] z; // OUTZ_{L, H}_A
} data_t;

// uses single byte spi internal module for writes
// and multi byte module for reading all fields
module imu_multi(
  input logic reset,
  input logic SDO, // Serial Data Output
  input logic clk,
  output logic SPC, // Serial Port Clock: 10 MHz (pg 14 of IMU datasheet)
  output logic CS, // Chip Select: SPI enable when 0
  output logic SDI, // Serial Data Input
  output data_t curr_data);

  enum logic [4:0] {START, // turn on time 35 ms pg 13
                    CTRL9_XL,
                    CTRL4_C,
                    CTRL2_G,
                    CTRL1_XL,
                    WAIT,
                    READ,
                    DONE} curr_state, next_state;
  data_t next_data;

  // internal spi modules do the hard work
  logic [7:0] addr, wdata, rdata_old;
  logic done_single, done_multi;
  logic enable_single, enable_multi;
  logic SPC_single, SPC_multi;
  logic CS_single, CS_multi;
  logic SDI_single, SDI_multi;
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
    .done(done_single));

  logic [95:0] rdata;
  // 12 bytes: 3 accel, 3 gyro, 2 bytes per field
  spi_multi #(12) spi_reader(
    .addr(addr),
    .clk(clk),
    .enable(enable_multi),
    .reset(reset),
    .SDO(SDO),
    .SPC(SPC_multi),
    .CS(CS_multi),
    .SDI(SDI_multi),
    .rdata(rdata),
    .done(done_multi));

  // mux for which outputs to use
  always_comb begin
    if (curr_state == READ) begin
      SPC = SPC_multi;
      CS = CS_multi;
      SDI = SDI_multi;
    end
    else begin
      SPC = SPC_single;
      CS = CS_single;
      SDI = SDI_single;
    end
  end

  // enable is an edge detection for new state
  logic next_enable_single, next_enable_multi;
  assign next_enable_single = ((curr_state != next_state)
                    && (next_state == CTRL9_XL
                    || next_state == CTRL4_C
                    || next_state == CTRL2_G
                    || next_state == CTRL1_XL));
  assign next_enable_multi = ((curr_state != next_state)
                    && (next_state == READ));

  // interfacing with internal spi module
  always_ff @(posedge clk) begin
    enable_single <= next_enable_single;
    enable_multi <= next_enable_multi;

    // addresses of registers from datasheet
    case (curr_state)
      CTRL9_XL: addr <= 8'h18;
      CTRL4_C: addr <= 8'h13;
      CTRL2_G: addr <= 8'h11; // these addresses are swapped
      CTRL1_XL: addr <= 8'h10; // but it doesn't really matter
      READ: addr <= 8'h22;
    endcase

    // writing states
    case (curr_state)
      CTRL9_XL: wdata <= 8'b1110_0010;
      CTRL4_C: wdata <= 8'b0000_0100;
      CTRL2_G: wdata <= 8'b0110_0000;
      CTRL1_XL: wdata <= 8'b0110_0000;
    endcase

  end

  always_ff @(posedge clk) begin
    // reading state
    case (curr_state)
      WAIT: next_data <= 96'd0;
      // need to reorganize bits since low order comes before high
      READ: next_data <= '{
        pitch: {rdata[15:8], rdata[7:0]},
        roll: {rdata[31:24], rdata[23:16]},
        yaw: {rdata[47:40], rdata[39:32]},
        x: {rdata[63:56], rdata[55:48]},
        y: {rdata[79:72], rdata[71:64]},
        z: {rdata[95:88], rdata[87:80]}
      };
    endcase
  end

  // counter to rate limit a bit and not overload imu
  parameter WAIT_CYCLES = 4_000_000;
  logic [$clog2(WAIT_CYCLES+1):0] wait_idx;
  logic clear;
  Counter #($clog2(WAIT_CYCLES+1)+1) wait_time(clk, clear, wait_idx);
  assign clear = curr_state == DONE || curr_state == CTRL1_XL;

  // wait time for between each config write
  parameter STATE_DELAY = 1000;
  logic [$clog2(STATE_DELAY+1):0] delay;
  logic clear2;
  Counter #($clog2(STATE_DELAY+1)+1) delay_time(clk, clear2, delay);

  // edge detector for done_single (only writing)
  edge_det done_edge(done_single, clk, clear2);

  // next state logic
  always_comb begin
    next_state = curr_state;
    case (curr_state)
      // turn on time is 35 ms
      START: next_state = (wait_idx == 700_000) ? CTRL9_XL : START;
      CTRL9_XL: next_state = (delay == STATE_DELAY) ? CTRL4_C : CTRL9_XL;
      CTRL4_C: next_state = (delay == STATE_DELAY) ? CTRL2_G : CTRL4_C;
      CTRL2_G: next_state = (delay == STATE_DELAY) ? CTRL1_XL: CTRL2_G;
      CTRL1_XL: next_state = (delay == STATE_DELAY) ? WAIT : CTRL1_XL;
      WAIT: next_state = (wait_idx == WAIT_CYCLES) ? READ : WAIT;
      READ: next_state = (done_multi) ? DONE : READ;
      DONE: next_state = WAIT;
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      curr_state <= START;
      curr_data <= 96'd0;
    end
    else begin
      curr_state <= next_state;
      if (next_state == DONE) curr_data <= next_data;
    end
  end

endmodule: imu_multi
