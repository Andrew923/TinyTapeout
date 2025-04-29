`default_nettype none

// super super explicit to completely match datasheet SPI spec
// section 4.4 pg 14
module spi(
  input logic [7:0] addr,
  input logic [7:0] wdata,
  input logic read,
  input logic clk,
  input logic enable,
  input logic reset,
  input logic SDO,
  output logic SPC,
  output logic CS,
  output logic SDI,
  output logic [7:0] rdata,
  output logic done);

  // 2 states per bit to write on falling edges and read on rising
  // also makes SPC speed half
  enum logic [5:0] {WAIT,
                    RW_n,
                    RW,
                    AD6_n,
                    AD6,
                    AD5_n,
                    AD5,
                    AD4_n,
                    AD4,
                    AD3_n,
                    AD3,
                    AD2_n,
                    AD2,
                    AD1_n,
                    AD1,
                    AD0_n,
                    AD0,
                    DI7_n,
                    DI7,
                    DI6_n,
                    DI6,
                    DI5_n,
                    DI5,
                    DI4_n,
                    DI4,
                    DI3_n,
                    DI3,
                    DI2_n,
                    DI2,
                    DI1_n,
                    DI1,
                    DI0_n,
                    DI0,
                    DONE, // DONE2 state for CS to go high after SPC
                    DONE2} curr_state, next_state;

  // next state logic
  always_comb begin
    next_state = curr_state;
    case (curr_state)
      WAIT: next_state = (enable) ? RW_n : WAIT;
      RW_n: next_state = RW;
      RW: next_state = AD6_n;
      AD6_n: next_state = AD6;
      AD6: next_state = AD5_n;
      AD5_n: next_state = AD5;
      AD5: next_state = AD4_n;
      AD4_n: next_state = AD4;
      AD4: next_state = AD3_n;
      AD3_n: next_state = AD3;
      AD3: next_state = AD2_n;
      AD2_n: next_state = AD2;
      AD2: next_state = AD1_n;
      AD1_n: next_state = AD1;
      AD1: next_state = AD0_n;
      AD0_n: next_state = AD0;
      AD0: next_state = DI7_n;
      DI7_n: next_state = DI7;
      DI7: next_state = DI6_n;
      DI6_n: next_state = DI6;
      DI6: next_state = DI5_n;
      DI5_n: next_state = DI5;
      DI5: next_state = DI4_n;
      DI4_n: next_state = DI4;
      DI4: next_state = DI3_n;
      DI3_n: next_state = DI3;
      DI3: next_state = DI2_n;
      DI2_n: next_state = DI2;
      DI2: next_state = DI1_n;
      DI1_n: next_state = DI1;
      DI1: next_state = DI0_n;
      DI0_n: next_state = DI0;
      DI0: next_state = DONE;
      DONE: next_state = DONE2;
      DONE2: next_state = WAIT;
    endcase
  end

  // output logic
  always_comb begin
    CS = (curr_state == WAIT || curr_state == DONE2);
    done = (curr_state == DONE2);
  end
  
  always_ff @(posedge clk) begin
    // input logic (capture on rising edge)
    case (curr_state)
      WAIT: rdata <= 8'd0;
      DI7: rdata[7] <= SDO;
      DI6: rdata[6] <= SDO;
      DI5: rdata[5] <= SDO;
      DI4: rdata[4] <= SDO;
      DI3: rdata[3] <= SDO;
      DI2: rdata[2] <= SDO;
      DI1: rdata[1] <= SDO;
      DI0: rdata[0] <= SDO;
    endcase

    // SPC
    case (curr_state)
      WAIT: SPC <= 1'b1;
      RW_n: SPC <= 1'b0;
      RW: SPC <= 1'b1;
      AD6_n: SPC <= 1'b0;
      AD6: SPC <= 1'b1;
      AD5_n: SPC <= 1'b0;
      AD5: SPC <= 1'b1;
      AD4_n: SPC <= 1'b0;
      AD4: SPC <= 1'b1;
      AD3_n: SPC <= 1'b0;
      AD3: SPC <= 1'b1;
      AD2_n: SPC <= 1'b0;
      AD2: SPC <= 1'b1;
      AD1_n: SPC <= 1'b0;
      AD1: SPC <= 1'b1;
      AD0_n: SPC <= 1'b0;
      AD0: SPC <= 1'b1;
      DI7_n: SPC <= 1'b0;
      DI7: SPC <= 1'b1;
      DI6_n: SPC <= 1'b0;
      DI6: SPC <= 1'b1;
      DI5_n: SPC <= 1'b0;
      DI5: SPC <= 1'b1;
      DI4_n: SPC <= 1'b0;
      DI4: SPC <= 1'b1;
      DI3_n: SPC <= 1'b0;
      DI3: SPC <= 1'b1;
      DI2_n: SPC <= 1'b0;
      DI2: SPC <= 1'b1;
      DI1_n: SPC <= 1'b0;
      DI1: SPC <= 1'b1;
      DI0_n: SPC <= 1'b0;
      DI0: SPC <= 1'b1;
      DONE: SPC <= 1'b1;
      DONE2: SPC <= 1'b1;
    endcase

    // SDI
    case (curr_state)
      // WAIT: SDI <= 1'b0;
      RW_n: SDI <= read;
      RW: SDI <= read;
      AD6_n: SDI <= addr[6];
      AD6: SDI <= addr[6];
      AD5_n: SDI <= addr[5];
      AD5: SDI <= addr[5];
      AD4_n: SDI <= addr[4];
      AD4: SDI <= addr[4];
      AD3_n: SDI <= addr[3];
      AD3: SDI <= addr[3];
      AD2_n: SDI <= addr[2];
      AD2: SDI <= addr[2];
      AD1_n: SDI <= addr[1];
      AD1: SDI <= addr[1];
      AD0_n: SDI <= addr[0];
      AD0: SDI <= addr[0];
      DI7_n: SDI <= (read) ? 1'b0 : wdata[7];
      DI7: SDI <= (read) ? 1'b0 : wdata[7];
      DI6_n: SDI <= (read) ? 1'b0 : wdata[6];
      DI6: SDI <= (read) ? 1'b0 : wdata[6];
      DI5_n: SDI <= (read) ? 1'b0 : wdata[5];
      DI5: SDI <= (read) ? 1'b0 : wdata[5];
      DI4_n: SDI <= (read) ? 1'b0 : wdata[4];
      DI4: SDI <= (read) ? 1'b0 : wdata[4];
      DI3_n: SDI <= (read) ? 1'b0 : wdata[3];
      DI3: SDI <= (read) ? 1'b0 : wdata[3];
      DI2_n: SDI <= (read) ? 1'b0 : wdata[2];
      DI2: SDI <= (read) ? 1'b0 : wdata[2];
      DI1_n: SDI <= (read) ? 1'b0 : wdata[1];
      DI1: SDI <= (read) ? 1'b0 : wdata[1];
      DI0_n: SDI <= (read) ? 1'b0 : wdata[0];
      DI0: SDI <= (read) ? 1'b0 : wdata[0];
      // DONE: SDI <= 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      curr_state <= WAIT;
    end
    else begin
      curr_state <= next_state;
    end
  end
endmodule: spi

// for multi-byte reading
module spi_multi
  #(parameter BYTES=12)
(
  input logic [7:0] addr,
  input logic clk,
  input logic enable,
  input logic reset,
  input logic SDO,
  output logic SPC,
  output logic CS,
  output logic SDI,
  output logic [8*BYTES-1:0] rdata,
  output logic done);

  // 2 states per bit to write on falling edges and read on rising
  // also makes SPC speed half
  enum logic [5:0] {WAIT,
                    RW_n,
                    RW,
                    AD6_n,
                    AD6,
                    AD5_n,
                    AD5,
                    AD4_n,
                    AD4,
                    AD3_n,
                    AD3,
                    AD2_n,
                    AD2,
                    AD1_n,
                    AD1,
                    AD0_n,
                    AD0,
                    DI7_n,
                    DI7,
                    DI6_n,
                    DI6,
                    DI5_n,
                    DI5,
                    DI4_n,
                    DI4,
                    DI3_n,
                    DI3,
                    DI2_n,
                    DI2,
                    DI1_n,
                    DI1,
                    DI0_n,
                    DI0,
                    DONE, // DONE2 state for CS to go high after SPC
                    DONE2} curr_state, next_state;

  // counter for how many bytes we've read
  logic [$clog2(BYTES+1):0] byte_idx;

  // next state logic
  always_comb begin
    next_state = curr_state;
    case (curr_state)
      WAIT: next_state = (enable) ? RW_n : WAIT;
      RW_n: next_state = RW;
      RW: next_state = AD6_n;
      AD6_n: next_state = AD6;
      AD6: next_state = AD5_n;
      AD5_n: next_state = AD5;
      AD5: next_state = AD4_n;
      AD4_n: next_state = AD4;
      AD4: next_state = AD3_n;
      AD3_n: next_state = AD3;
      AD3: next_state = AD2_n;
      AD2_n: next_state = AD2;
      AD2: next_state = AD1_n;
      AD1_n: next_state = AD1;
      AD1: next_state = AD0_n;
      AD0_n: next_state = AD0;
      AD0: next_state = DI7_n;
      DI7_n: next_state = DI7;
      DI7: next_state = DI6_n;
      DI6_n: next_state = DI6;
      DI6: next_state = DI5_n;
      DI5_n: next_state = DI5;
      DI5: next_state = DI4_n;
      DI4_n: next_state = DI4;
      DI4: next_state = DI3_n;
      DI3_n: next_state = DI3;
      DI3: next_state = DI2_n;
      DI2_n: next_state = DI2;
      DI2: next_state = DI1_n;
      DI1_n: next_state = DI1;
      DI1: next_state = DI0_n;
      DI0_n: next_state = DI0;
      DI0: next_state = (byte_idx + 1 < BYTES) ? DI7_n : DONE;
      DONE: next_state = DONE2;
      DONE2: next_state = WAIT;
    endcase
  end

  // output logic
  always_comb begin
    CS = (curr_state == WAIT || curr_state == DONE2);
    done = (curr_state == DONE2);
  end
  
  always_ff @(posedge clk) begin
    // input logic (capture on rising edge)
    case (curr_state)
      WAIT: rdata <= 96'd0;
      DI7: rdata[(byte_idx << 3) + 7] <= SDO;
      DI6: rdata[(byte_idx << 3) + 6] <= SDO;
      DI5: rdata[(byte_idx << 3) + 5] <= SDO;
      DI4: rdata[(byte_idx << 3) + 4] <= SDO;
      DI3: rdata[(byte_idx << 3) + 3] <= SDO;
      DI2: rdata[(byte_idx << 3) + 2] <= SDO;
      DI1: rdata[(byte_idx << 3) + 1] <= SDO;
      DI0: rdata[(byte_idx << 3) + 0] <= SDO;
    endcase

    // SPC
    case (curr_state)
      WAIT: SPC <= 1'b1;
      RW_n: SPC <= 1'b0;
      RW: SPC <= 1'b1;
      AD6_n: SPC <= 1'b0;
      AD6: SPC <= 1'b1;
      AD5_n: SPC <= 1'b0;
      AD5: SPC <= 1'b1;
      AD4_n: SPC <= 1'b0;
      AD4: SPC <= 1'b1;
      AD3_n: SPC <= 1'b0;
      AD3: SPC <= 1'b1;
      AD2_n: SPC <= 1'b0;
      AD2: SPC <= 1'b1;
      AD1_n: SPC <= 1'b0;
      AD1: SPC <= 1'b1;
      AD0_n: SPC <= 1'b0;
      AD0: SPC <= 1'b1;
      DI7_n: SPC <= 1'b0;
      DI7: SPC <= 1'b1;
      DI6_n: SPC <= 1'b0;
      DI6: SPC <= 1'b1;
      DI5_n: SPC <= 1'b0;
      DI5: SPC <= 1'b1;
      DI4_n: SPC <= 1'b0;
      DI4: SPC <= 1'b1;
      DI3_n: SPC <= 1'b0;
      DI3: SPC <= 1'b1;
      DI2_n: SPC <= 1'b0;
      DI2: SPC <= 1'b1;
      DI1_n: SPC <= 1'b0;
      DI1: SPC <= 1'b1;
      DI0_n: SPC <= 1'b0;
      DI0: SPC <= 1'b1;
      DONE: SPC <= 1'b1;
      DONE2: SPC <= 1'b1;
    endcase

    // SDI
    case (curr_state)
      RW_n: SDI <= 1'b1; // always read
      RW: SDI <= 1'b1;
      AD6_n: SDI <= addr[6];
      AD6: SDI <= addr[6];
      AD5_n: SDI <= addr[5];
      AD5: SDI <= addr[5];
      AD4_n: SDI <= addr[4];
      AD4: SDI <= addr[4];
      AD3_n: SDI <= addr[3];
      AD3: SDI <= addr[3];
      AD2_n: SDI <= addr[2];
      AD2: SDI <= addr[2];
      AD1_n: SDI <= addr[1];
      AD1: SDI <= addr[1];
      AD0_n: SDI <= addr[0];
      AD0: SDI <= addr[0];
    endcase
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      curr_state <= WAIT;
    end
    else begin
      curr_state <= next_state;
      if (next_state == AD0)
        byte_idx <= 0;
      if (curr_state != next_state && curr_state == DI0)
        byte_idx <= byte_idx + 1;
    end
  end
endmodule: spi_multi
