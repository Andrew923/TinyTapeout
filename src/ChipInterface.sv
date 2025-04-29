`default_nettype none

// debug macro since pll doesn't work well with cocotb
`define DEBUG

module ChipInterface
  (output logic led_data,
   output logic [7:0] led,
   output logic SDI, // Serial Data Input
   output logic SPC, // Serial Port Clock: 10 MHz (pg 14 of IMU datasheet)
   output logic CS, // Chip Select: SPI enable when 0
   input logic SDO,
   input logic btn_left, btn_right,
   input logic btn_up, btn_down,
   input logic rst, clk);

  logic reset, locked;
  logic clk10;
  data_t data;
  logic matrix[15:0][15:0];

  ws2812 led_module(
    .clock(clk),
    .reset(reset),
    .imu_data(data),
    .matrix(matrix),
    .o_out(led_data));
  `ifdef DEBUG
  logic toggle;
  always_ff @(posedge clk) begin
    toggle <= ~toggle;
    if (toggle)
      clk10 <= ~clk10;
  end
  `else
  pll spc_clock(.*);
  `endif
  imu_multi sensor(
    .reset(reset),
    .SDO(SDO),
    .clk(clk),
    .CS(CS),
    .SPC(SPC),
    .SDI(SDI),
    .curr_data(data));
  physics simulator(
    .data(data),
    .clk(clk10),
    .reset(reset),
    .btn_left(btn_left),
    .btn_right(btn_right),
    .btn_up(btn_up),
    .btn_down(btn_down),
    .matrix(matrix));

  always_comb begin
    led[7:4] = data.x[15:12];
    led[3:0] = data.y[15:12];
    `ifdef DEBUG
    reset = rst;
    `else
    reset = ~locked || rst;
    `endif
  end
endmodule: ChipInterface
