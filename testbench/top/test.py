import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, First
from cocotb.utils import get_sim_time
from PIL import Image
from tqdm import tqdm

async def step_clock(dut):
    dut.clk.value = 1
    await Timer(10, units="ns")
    dut.clk.value = 0
    await Timer(10, units="ns")
   
# helper function to extract current particle positions
async def get_positions(dut):
    dir(dut)
    physics = dut._HierarchyObject__get_sub_handle_by_name('simulator')
    return [(int(physics.cx.value) >> 4, int(physics.cy.value) >> 4),
            (int(physics.p0x.value) >> 4, int(physics.p0y.value) >> 4),
            (int(physics.p1x.value) >> 4, int(physics.p1y.value) >> 4),
            (int(physics.p2x.value) >> 4, int(physics.p2y.value) >> 4)]

# just for generating dump.vcd to look at
@cocotb.test()
async def waveform_test(dut):
    # reset
    dut.rst_n.value = 0
    await step_clock(dut)
    dut.rst_n.value = 1
    for _ in range(100_000):
        await step_clock(dut)

# test if initial matrix pattern is observed
@cocotb.test()
async def init_test(dut):
    # reset
    dut.rst_n.value = 0
    await step_clock(dut)
    dut.rst_n.value = 1

    # wait a bit with no inputs
    for _ in range(11_000):
        await step_clock(dut)

    points = [(8, 8), (6, 10), (8, 6), (10, 10)]
    print(f"Initial Points: {points}")
    print(f"Actual points: {await get_positions(dut)}")

    matrix_str = str(dut.matrix.value)[::-1]
    print("Matrix:")
    for i in range(16):
        print(matrix_str[i*16:i*16+16])

    passed = True
    for i in range(16):
        for j, v in enumerate(matrix_str[i*16:i*16+16]):
            # if any(((x - j) ** 2 + (y - i) ** 2) ** 0.5 <= 2 for x, y in points):
            if any((-2 <= x - j <= 2)
                   and (-2 <= y - i <= 2)
                   and (x - j + y - i <= 3)
                   and (x - j - (y - i) <= 3)
                   and (y - i - (x - j) <= 3)
                   and (x - j + y - i >= -3) for x, y in points):
                if (int(v) != 1):
                    print(f"mismatch at point ({i}, {j}) expected 1, got {v}")
                    passed = False
            else:
                if (int(v) != 0):
                    print(f"mismatch at point ({i}, {j}) expected 0, got {v}")
                    passed = False
    assert passed

# # test that led data is correct
@cocotb.test()
async def ws2812_test(dut):
    print("============== STARTING TEST ==============")

    # Run the clock
    # 50nS (=0.05uS) is the period of a 20MHz clock
    cocotb.start_soon(Clock(dut.clk, 50, units="ns").start())

    # Since our circuit is on the rising edge,
    # we can feed inputs on the falling edge
    # This makes things easier to read and visualize
    await FallingEdge(dut.clk)

    # Reset the DUT
    dut.rst_n.value = False
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.rst_n.value = True

    start_time = get_sim_time(units="us")
    print("Starting at", start_time)

    # wait a bit with no inputs
    for _ in range(10_400):
        await FallingEdge(dut.clk)

    matrix_str = str(dut.matrix.value)[::-1]
    print("Matrix:")
    for i in range(16):
        print(matrix_str[i*16:i*16+16])

    # grab 16x16 matrix
    times = list()
    curr_color = list()
    colors = list()

    # wait for a multiple of 256 so we start at the right bit
    await RisingEdge(dut.led_data)
    curr = get_sim_time(units="us")
    while (diff :=((curr - start_time) % (1.25 * 256))) > 1.25 and diff < (320 - 1.25):
        await RisingEdge(dut.led_data)
        curr = get_sim_time(units="us")

    with tqdm(total=256, desc="Pixels") as pbar:
        while len(colors) < 256:
            await RisingEdge(dut.led_data)
            if not dut.led_data.value:
                continue
            start = get_sim_time(units="ns")
            await FallingEdge(dut.led_data)
            times.append(get_sim_time(units="ns") - start)

            # for every 8 bits, we sort measured times to find
            # cutoff between low and high times
            if len(times) == 8:
                ordered = sorted(times)
                maxdiff, cutoff = 0, float('inf')
                for i in range(len(ordered) - 1):
                    diff = ordered[i + 1] - ordered[i]
                    if diff > maxdiff:
                        maxdiff, cutoff = diff, ordered[i]

                # convert to bytes
                bools = [int(t > cutoff) for t in times]
                curr_color.append(int("".join(map(str, bools)), 2))
                if len(curr_color) == 3:
                    colors.append(tuple(curr_color))
                    pbar.update(1)
                    curr_color = list()
                times = list()
    print("Done at", get_sim_time(units="ns"))
    print(f"Colors (r, g, b): {colors}")


    # Image logic
    im = Image.new("RGB", (16, 16))
    colors = [(r << 2, g << 2, b << 2) for r, g, b in colors]
    im.putdata(colors)
    im = im.resize((im.width*32, im.height*32), Image.NEAREST)
    im.save("leds.png")
