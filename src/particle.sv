`default_nettype none

// Note: because of lack of floats, treat
// integers like int >>> 4 where lowest
// 4 bits are decimal points

// handles logic for specific particle
// in 16x16 grid
module particle
  #(parameter shortint MASS=8,
    parameter shortint INIT_X=8*16,
    parameter shortint INIT_Y=8*16,
    parameter shortint REST0=4*16, // rest lengths for each other particle
    parameter shortint REST1=4*16,
    parameter shortint REST2=4*16,
    parameter shortint PHASE_OFFSET=0)
(
  // handles influence from 3 particles
  input shortint x0, y0, m0, vx0, vy0, 
  input shortint x1, y1, m1, vx1, vy1, 
  input shortint x2, y2, m2, vx2, vy2, 
  input data_t data,
  input logic clk,
  input logic reset,
  output shortint x, y, m, vel_x, vel_y
);

  // simulation parameters
  parameter WIDTH = 16*16;

  // store position, velocity, acceleration
  shortint px;
  shortint py;
  shortint px_old; // needed for Verlet integration
  shortint py_old;
  shortint vx;
  shortint vy;
  shortint ax;
  shortint ay;
  shortint force_x, force_y;
  shortint imu_x, imu_y;

  // temporary variables used during updating
  shortint dx0, dy0, dx1, dy1, dx2, dy2; // deltas
  shortint d0, d1, d2; // distances
  shortint displace0, displace1, displace2;
  shortint rel_vel_x0, rel_vel_x1, rel_vel_x2; // relative velocity
  shortint rel_vel_y0, rel_vel_y1, rel_vel_y2; // for dampening
  shortint dampx0, dampx1, dampx2; // x component of dampening
  shortint dampy0, dampy1, dampy2; // y component of dampening
  shortint damp0, damp1, damp2; // dampened amount

  // variables for time division multiplexing multiplication
  shortint multa, multb;

  // counter for pipelining stages
  parameter TOTAL_CYCLES = 300_000;
  // parameter TOTAL_CYCLES = 500;
  logic [$clog2(TOTAL_CYCLES+1):0] idx;
  logic clear;
  Counter #($clog2(TOTAL_CYCLES+1)+1) counter(clk, clear, idx);
  assign clear = reset;

  always_comb begin
    // outputs
    x = px;
    y = py;
    m = MASS;
    vel_x = vx;
    vel_y = vy;
  end

  // mux for multa, multb
  always_comb begin
    case (idx)
      PHASE_OFFSET + 9: begin
        multa = px - x0;
        multb = px - x0;
      end
      PHASE_OFFSET + 10: begin
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
        multa = (displace0) + damp0;
        multb = dx0;
      end
      PHASE_OFFSET + 21: begin
        multa = (displace0) + damp0;
        multb = dy0;
      end
      PHASE_OFFSET + 22: begin
        multa = px - x1;
        multb = px - x1;
      end
      PHASE_OFFSET + 23: begin
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
      PHASE_OFFSET + 33: begin
        multa = (displace1) + damp1;
        multb = dx1;
      end
      PHASE_OFFSET + 34: begin
        multa = (displace1) + damp1;
        multb = dy1;
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
        multa = (displace2) + damp2;
        multb = dx2;
      end
      PHASE_OFFSET + 47: begin
        multa = (displace2) + damp2;
        multb = dy2;
      end
      default: begin
        multa = 0;
        multb = 0;
      end
    endcase
  end
  
  // sequential updates
  always_ff @(posedge clk) begin
    //////////////////////////////
    // Initalization
    //////////////////////////////
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
    else begin // update function in python version
      //////////////////////////////
      // Updating phases
      //////////////////////////////
      case (idx)
        PHASE_OFFSET + 0: begin
          // Phase 0: force update
          force_x <= imu_x;
          force_y <= -imu_y;
        end
        //////////////////////////////
        // Phases 1-8: parameter update
        //////////////////////////////
        PHASE_OFFSET + 1: begin
          px <= (px << 1) - px_old + ax;
        end
        PHASE_OFFSET + 2: begin
          py <= (py << 1) - py_old + ay;
        end
        PHASE_OFFSET + 3: begin
          ax <= 0;
        end
        PHASE_OFFSET + 4: begin
          ay <= 0;
        end
        PHASE_OFFSET + 5: begin
          vx <= (px - px_old) >>> 1;
        end
        PHASE_OFFSET + 6: begin
          vy <= (py - py_old) >>> 1;
        end
        PHASE_OFFSET + 7: begin
          px_old <= px;
        end
        PHASE_OFFSET + 8: begin
          py_old <= py;
        end

        //////////////////////////////
        // Phases 9-11: distance mass 0
        //////////////////////////////
        PHASE_OFFSET + 9: begin
          dx0 <= (multa * multb) >>> 4; // dx^2
        end
        PHASE_OFFSET + 10: begin
          dy0 <= (multa * multb) >>> 4; // dy^2
        end
        PHASE_OFFSET + 11: begin
          // euclidean distance squared
          d0 <= dx0 + dy0; // no sqrt :(
        end
        //////////////////////////////
        // Phases 12-16: parameter update
        //////////////////////////////
        PHASE_OFFSET + 12: begin
          if (d0 > 0) begin
            dx0 <= dx0 / d0;
          end
        end
        PHASE_OFFSET + 13: begin
          if (d0 > 0) begin
            dy0 <= dy0 / d0;
          end
        end
        PHASE_OFFSET + 14: begin
          if (d0 > 0) begin
            displace0 <= d0 - REST0;
          end
        end
        PHASE_OFFSET + 15: begin
          if (d0 > 0) begin
            rel_vel_x0 <= vx - vx0;
          end
        end
        PHASE_OFFSET + 16: begin
          if (d0 > 0) begin
            rel_vel_y0 <= vy - vy0;
          end
        end
        //////////////////////////////
        // Phases 17-19: damping
        //////////////////////////////
        PHASE_OFFSET + 17: begin
          if (d0 > 0) begin
            dampx0 <= (multa * multb) >>> 4; // rel_vel_x0 * dx0
          end
        end
        PHASE_OFFSET + 18: begin
          if (d0 > 0) begin
            dampy0 <= (multa * multb) >>> 4; // rel_vel_y0 * dy0
          end
        end
        PHASE_OFFSET + 19: begin
          if (d0 > 0) begin
            damp0 <= (dampx0 + dampy0) >>> 2;
          end
        end
        PHASE_OFFSET + 20: begin
          if (d0 > 0) begin
            ax <= ax + ((multa * multb) >>> 4); // ax + (((displace0) + damp0) * dx0)
          end
        end
        PHASE_OFFSET + 21: begin
          if (d0 > 0) begin
            ay <= ay + ((multa * multb) >>> 4); // ay + (((displace0) + damp0) * dy0)
          end
        end

        //////////////////////////////
        // Phases 22-24: distance mass 1
        //////////////////////////////
        PHASE_OFFSET + 22: begin
          dx1 <= (multa * multb) >>> 4; // dx^2
        end
        PHASE_OFFSET + 23: begin
          dy1 <= (multa * multb) >>> 4; // dy^2
        end
        PHASE_OFFSET + 24: begin
          // euclidean distance squared
          d1 <= dx1 + dy1; // no sqrt :(
        end
        //////////////////////////////
        // Phases 25-29: parameter update
        //////////////////////////////
        PHASE_OFFSET + 25: begin
          if (d1 > 0) begin
            dx1 <= dx1 / d1;
          end
        end
        PHASE_OFFSET + 26: begin
          if (d1 > 0) begin
            dy1 <= dy1 / d1;
          end
        end
        PHASE_OFFSET + 27: begin
          if (d1 > 0) begin
            displace1 <= d1 - REST1;
          end
        end
        PHASE_OFFSET + 28: begin
          if (d1 > 0) begin
            rel_vel_x1 <= vx - vx1;
          end
        end
        PHASE_OFFSET + 29: begin
          if (d1 > 0) begin
            rel_vel_y1 <= vy - vy1;
          end
        end
        //////////////////////////////
        // Phases 30-32: damping
        //////////////////////////////
        PHASE_OFFSET + 30: begin
          if (d1 > 0) begin
            dampx1 <= (multa * multb) >>> 4; // rel_vel_x1 * dx1
          end
        end
        PHASE_OFFSET + 31: begin
          if (d1 > 0) begin
            dampy1 <= (multa * multb) >>> 4; // rel_vel_y1 * dy1
          end
        end
        PHASE_OFFSET + 32: begin
          if (d1 > 0) begin
            damp1 <= (dampx1 + dampy1) >>> 2;
          end
        end
        PHASE_OFFSET + 33: begin
          if (d1 > 0) begin
            ax <= ax + ((multa * multb) >>> 4); // ax + (((displace1) + damp1) * dx1);
          end
        end
        PHASE_OFFSET + 34: begin
          if (d1 > 0) begin
            ay <= ay + ((multa * multb) >>> 4); // ay + (((displace1) + damp1) * dy1);
          end
        end

        //////////////////////////////
        // Phases 35-37: distance mass 2
        //////////////////////////////
        PHASE_OFFSET + 35: begin
          dx2 <= (multa * multb) >>> 4; // dx^2
        end
        PHASE_OFFSET + 36: begin
          dy2 <= (multa * multb) >>> 4; // dy^2
        end
        PHASE_OFFSET + 37: begin
          // euclidean distance squared
          d2 <= dx2 + dy2; // no sqrt :(
        end
        //////////////////////////////
        // Phases 38-42: parameter update
        //////////////////////////////
        PHASE_OFFSET + 38: begin
          if (d2 > 0) begin
            dx2 <= dx2 / d2;
          end
        end
        PHASE_OFFSET + 39: begin
          if (d2 > 0) begin
            dy2 <= dy2 / d2;
          end
        end
        PHASE_OFFSET + 40: begin
          if (d2 > 0) begin
            displace2 <= d2 - REST2;
          end
        end
        PHASE_OFFSET + 41: begin
          if (d2 > 0) begin
            rel_vel_x2 <= vx - vx2;
          end
        end
        PHASE_OFFSET + 42: begin
          if (d2 > 0) begin
            rel_vel_y2 <= vy - vy2;
          end
        end
        //////////////////////////////
        // Phases 43-45: damping
        //////////////////////////////
        PHASE_OFFSET + 43: begin
          if (d2 > 0) begin
            dampx2 <= (multa * multb) >>> 4; // rel_vel_x2 * dx2
          end
        end
        PHASE_OFFSET + 44: begin
          if (d2 > 0) begin
            dampy2 <= (multa * multb) >>> 4; // rel_vel_y2 * dy2
          end
        end
        PHASE_OFFSET + 45: begin
          if (d2 > 0) begin
            damp2 <= (dampx2 + dampy2) >>> 2;
          end
        end
        PHASE_OFFSET + 46: begin
          if (d2 > 0) begin
            ax <= ax + ((multa * multb) >>> 4); // ax + (((displace2) + damp2) * dx2)
          end
        end
        PHASE_OFFSET + 47: begin
          if (d2 > 0) begin
            ay <= ay + ((multa * multb) >>> 4); // ay + (((displace2) + damp2) * dy2)
          end
        end

        //////////////////////////////
        // Phases 48-51: boundary checks
        //////////////////////////////
        PHASE_OFFSET + 48: begin
          if (px < 0) begin
            px <= 0;
            vx <= -(vx >>> 1);
          end
        end
        PHASE_OFFSET + 49: begin
          if (px >= WIDTH) begin
            px <= WIDTH - 1;
            vx <= -(vx >>> 1);
          end
        end
        PHASE_OFFSET + 50: begin
          if (py < 0) begin
            py <= 0;
            vy <= -(vx >>> 1);
          end
        end
        PHASE_OFFSET + 51: begin
          if (py >= WIDTH) begin
            py <= WIDTH - 1;
            vy <= -(vx >>> 1);
          end
        end
      endcase

    end
  end

endmodule: particle

// handles logic for center particle
// which is only affected by external force
module center
  #(parameter shortint MASS=1*16,
    parameter shortint INIT_X=8*16,
    parameter shortint INIT_Y=8*16,
    parameter shortint PHASE_OFFSET=0)
(
  // other 3 particles info
  input shortint x0, y0, m0, vx0, vy0, 
  input shortint x1, y1, m1, vx1, vy1, 
  input shortint x2, y2, m2, vx2, vy2, 
  input data_t data,
  input logic clk,
  input logic reset,
  output shortint x, y, m, vel_x, vel_y
);

  // simulation parameters
  parameter WIDTH = 16*16;

  // store position, velocity, acceleration
  shortint px;
  shortint py;
  shortint px_old; // needed for Verlet integration
  shortint py_old;
  shortint vx;
  shortint vy;
  shortint ax;
  shortint ay;
  shortint force_x, force_y;
  shortint imu_x, imu_y;

  // temporary variables used during updating
  shortint dx0, dy0, dx1, dy1, dx2, dy2; // deltas
  shortint d0, d1, d2; // distances
  shortint displace0, displace1, displace2;
  shortint rel_vel_x0, rel_vel_x1, rel_vel_x2; // relative velocity
  shortint rel_vel_y0, rel_vel_y1, rel_vel_y2; // for dampening
  shortint dampx0, dampx1, dampx2; // x component of dampening
  shortint dampy0, dampy1, dampy2; // y component of dampening
  shortint damp0, damp1, damp2; // dampened amount

  // variables for time division multiplexing multiplication
  shortint multa, multb;

  // counter for pipelining stages
  parameter TOTAL_CYCLES = 300_000;
  // parameter TOTAL_CYCLES = 500;
  logic [$clog2(TOTAL_CYCLES+1):0] idx;
  logic clear;
  Counter #($clog2(TOTAL_CYCLES+1)+1) counter(clk, clear, idx);
  assign clear = reset;

  always_comb begin
    // outputs
    x = px;
    y = py;
    m = MASS;
    vel_x = vx;
    vel_y = vy;

    // inputs
    imu_x = shortint'(data.x) >>> 7;
    imu_y = shortint'(data.y) >>> 7;
  end

  // sequential updates
  always_ff @(posedge clk) begin
    //////////////////////////////
    // Initalization
    //////////////////////////////
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
    else begin // update function in python version
      //////////////////////////////
      // Updating phases
      //////////////////////////////
      case (idx)
        PHASE_OFFSET + 0: begin
          // Phase 0: force update
          force_x <= imu_x;
          force_y <= -imu_y;
        end
        //////////////////////////////
        // Phases 1-8: parameter update
        //////////////////////////////
        PHASE_OFFSET + 1: begin
          // ax <= (MASS == 16) ? (force_x >>> 4) : (force_x >>> 3); // force_x / MASS
          ax <= force_x >>> $clog2(MASS);
        end
        PHASE_OFFSET + 2: begin
          // ay <= (MASS == 16) ? (force_y >>> 4) : (force_y >>> 3); // force_y / MASS
          ay <= force_y >>> $clog2(MASS);
        end
        PHASE_OFFSET + 3: begin
          px <= (px << 1) - px_old + ax;
        end
        PHASE_OFFSET + 4: begin
          py <= (py << 1) - py_old + ay;
        end
        PHASE_OFFSET + 5: begin
          vx <= (px - px_old) >>> 1;
        end
        PHASE_OFFSET + 6: begin
          vy <= (py - py_old) >>> 1;
        end
        PHASE_OFFSET + 7: begin
          px_old <= px;
        end
        PHASE_OFFSET + 8: begin
          py_old <= py;
        end

        //////////////////////////////
        // Phases 48-51: boundary checks
        //////////////////////////////
        PHASE_OFFSET + 48: begin
          if (px < 0) begin
            px <= 0;
            vx <= -(vx >>> 1);
          end
        end
        PHASE_OFFSET + 49: begin
          if (px >= WIDTH) begin
            px <= WIDTH - 1;
            vx <= -(vx >>> 1);
          end
        end
        PHASE_OFFSET + 50: begin
          if (py < 0) begin
            py <= 0;
            vy <= -(vx >>> 1);
          end
        end
        PHASE_OFFSET + 51: begin
          if (py >= WIDTH) begin
            py <= WIDTH - 1;
            vy <= -(vx >>> 1);
          end
        end
      endcase

    end
  end

endmodule: center
