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
   
# for observing parameter values in waveform
@cocotb.test()
async def waveform_test(dut):
    # reset
    dut.reset.value = 1
    await step_clock(dut)
    dut.reset.value = 0

    #generate interesting movements by varying x and y
    dut.data.value = (0b1101_0000_0000_0000) << 32
    for _ in range(10_000):
        await step_clock(dut)

    dut.data.value = (0b1101_0000_0000_0000) << 16
    for _ in range(10_000):
        await step_clock(dut)

    dut.data.value = (0b0001_0110_0000_0000) << 32
    for _ in range(10_000):
        await step_clock(dut)

    dut.data.value = (0b0001_0110_0000_0000) << 16
    for _ in range(10_000):
        await step_clock(dut)

    dut.data.value = ((0b0001_0110_0000_0000) << 32) | ((0b0001_0110_0000_0000) << 16)
    for _ in range(30_000):
        await step_clock(dut)

