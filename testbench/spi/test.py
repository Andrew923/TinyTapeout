import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, First
from cocotb.triggers import Timer
from cocotb.utils import get_sim_time

async def step_clock(dut):
    dut.clk.value = 1
    await Timer(10, units="ns")
    dut.clk.value = 0
    await Timer(10, units="ns")
   
# just for generating dump.vcd to look at
@cocotb.test()
async def waveform_test(dut):
    # reset
    dut.reset.value = 1
    await step_clock(dut)
    dut.reset.value = 0
    dut.addr.value = 0x22
    dut.enable.value = 1
    for _ in range(1000):
        await step_clock(dut)


# spi test
# @cocotb.test()
async def simple_spi_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    # reset
    await FallingEdge(dut.clk)
    dut.reset.value = 1
    await FallingEdge(dut.clk)
    dut.reset.value = 0

    # config
    dut.addr.value = 0x2A
    dut.read.value = 1
    dut.enable.value = 1

    await FallingEdge(dut.CS)

    # RW bit
    await RisingEdge(dut.SPC)
    if dut.SDI.value != 1:
        assert False, "SDI should be 1 for read"

    # Addr bits
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 0
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 1
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 0
    
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 1
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 0
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 1
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 0

    # Data bits
    await FallingEdge(dut.SPC)
    dut.SDO.value = 1
    await FallingEdge(dut.SPC)
    dut.SDO.value = 0
    await FallingEdge(dut.SPC)
    dut.SDO.value = 1
    await FallingEdge(dut.SPC)
    dut.SDO.value = 0

    await FallingEdge(dut.SPC)
    dut.SDO.value = 0
    await FallingEdge(dut.SPC)
    dut.SDO.value = 1
    await FallingEdge(dut.SPC)
    dut.SDO.value = 1
    await FallingEdge(dut.SPC)
    dut.SDO.value = 0

    # read data
    # print(dut.rdata.value)
    await RisingEdge(dut.done)
    assert int(dut.rdata.value) == 0xA6
   

# multi bit spi test
@cocotb.test()
async def spi_multi_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    # reset
    await FallingEdge(dut.clk)
    dut.reset.value = 1
    await FallingEdge(dut.clk)
    dut.reset.value = 0
    
    dut.addr.value = 0x2A
    dut.enable.value = 1

    await FallingEdge(dut.CS)

    # RW bit
    await RisingEdge(dut.SPC)
    if dut.SDI.value != 1:
        assert False, "SDI should be 1 for read"

    # Addr bits
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 0
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 1
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 0
    
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 1
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 0
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 1
    await RisingEdge(dut.SPC)
    assert dut.SDI.value == 0

    # Data bits
    data = 0xFEDCBA654321013579BD0124
    bin_data = bin(data)[2:]
    for i in range(96):
        await FallingEdge(dut.SPC)
        dut.SDO.value = int(bin_data[i])
        
    # print(get_sim_time(units="ns"))

    # read data
    # print(dut.rdata.value)
    await RisingEdge(dut.done)
    # print(get_sim_time(units="ns"))
    result = str(dut.rdata.value)
    for i in range(12):
        byte = result[8*i:8*i+8]
        j = 96 - 8*(i+1)
        assert byte == bin_data[j:j+8]
    


