`default_nettype none

typedef struct packed {
    logic [7:0] red;
    logic [7:0] green;
    logic [7:0] blue;
} color_t;

module ws2812 (
    input logic clock,
    input logic reset,
    input data_t imu_data,
    input logic matrix[15:0][15:0],

    // Output to the RGB LEDs
    output logic o_out
);

    parameter CLK_FREQ = 20_000_000; // 20MHz = 0.05uS clk period

    parameter NUM_LEDS = 256;
    parameter NUM_FRAMES = 1;

    logic old_matrix[15:0][15:0];
    logic [$clog2(NUM_FRAMES+1):0] frame_idx;
    logic update, busy;
    color_t data[NUM_LEDS];
    logic in_bounds, done;

    // matrix display logic
    always_comb begin
        // loop through 2 rows at a time
        for (int start = 0; start < 256; start = start + 32) begin
            // reverse even rows
            for (int led_idx = start; led_idx < start + 16; led_idx++) begin
                data[(start << 1) + 15 - led_idx] = '{
                    red: old_matrix[led_idx >> 4][led_idx & 15] ? 8'd4 + ((led_idx >> 6) & 3): 8'd0,
                    green: old_matrix[led_idx >> 4][led_idx & 15] ? 8'd4 + ((led_idx >> 5) & 3): 8'd0,
                    blue: old_matrix[led_idx >> 4][led_idx & 15] ? 8'd4 + ((led_idx >> 4) & 3): 8'd0
                };
            end
            for (int led_idx = start + 16; led_idx < start + 32; led_idx++) begin
                data[led_idx] = '{
                    red: old_matrix[led_idx >> 4][led_idx & 15] ? 8'd4 + ((led_idx >> 6) & 3): 8'd0,
                    green: old_matrix[led_idx >> 4][led_idx & 15] ? 8'd4 + ((led_idx >> 5) & 3): 8'd0,
                    blue: old_matrix[led_idx >> 4][led_idx & 15] ? 8'd4 + ((led_idx >> 4) & 3): 8'd0
                };
            end
        end
    end

    // Sequencing logic modified to reset frame_idx when done
    always_ff @(posedge clock) begin
        update <= 0;

        if (reset || done) begin
            frame_idx <= 0;
            old_matrix <= matrix;
        end
        else if (frame_idx < NUM_FRAMES && !busy) begin
            update <= 1;
        end

        if (update) begin
            frame_idx <= frame_idx + 1;
        end
    end

    assign done = (frame_idx >= NUM_FRAMES) && !busy && !update;

    // Instantiate the WS2812 controller
    ws2812_inner #(
        .NUM_LEDS(NUM_LEDS),
        .CLK_FREQ(CLK_FREQ)
    ) ws (
        .o_out,
        .busy,
        .data, .update,
        .clock,
        .reset
    );

endmodule

// EX5
module ws2812_inner #(
    parameter NUM_LEDS = 7,
    parameter CLK_FREQ = 10000000
) (
    output logic o_out,
    output logic busy,

    // Note: this is not supported by Yosys
    // In order to synthesize this, must run it
    // through sv2v first (and feed the output to Yosys)
    input color_t data[NUM_LEDS],

    input logic update,

    input logic clock,
    input logic reset
);

    localparam T0H = $rtoi(CLK_FREQ / (1000000 / 0.4)); // 0.4us
    localparam T1H = $rtoi(CLK_FREQ / (1000000 / 0.8)); // 0.8us
    localparam T0L = $rtoi(CLK_FREQ / (1000000 / 0.85)); // 0.85us
    localparam T1L = $rtoi(CLK_FREQ / (1000000 / 0.45)); // 0.45us

    // Latch time as per datasheet is 50us; but LEDs don't work unless 200us
    localparam LATCH_TIME = $rtoi(CLK_FREQ / (1000000 / 200)); // 200us
    localparam PULSE_WIDTH = $rtoi(CLK_FREQ / (1000000 / 1.25));

    color_t data_int[NUM_LEDS];

    // LED Control Logic
    logic [8:0] led_index = 0;
    logic [5:0] bit_index = 0;
    logic [6:0] current_bit_index = 0;
    logic [17:0] latch_ctr = 0;
    logic refresh = 0;

    assign busy = refresh;

    logic [23:0] cur_led_dat;
    logic cur_bit_dat;

    assign cur_led_dat = {data_int[led_index].green, data_int[led_index].red, data_int[led_index].blue};
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

                // TODO: this can be refactored to synthesize cleaner
                if (current_bit_index + 1 == PULSE_WIDTH) begin
                    current_bit_index <= 0;
                    bit_index <= bit_index + 1;

                    if (bit_index + 1 == 24) begin
                        bit_index <= 0;

                        if (led_index + 1 == NUM_LEDS) begin
                            led_index <= 0;
                            latch_ctr <= LATCH_TIME;
                        end
                    end

                    // Pre-increment index so block RAM can be ready
                    if (bit_index + 1 == 24) begin
                        led_index <= led_index + 1;
                    end
                end

                o_out <= current_bit_index < (cur_bit_dat ? T1H : (T0H));
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

