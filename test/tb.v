`default_nettype none
`timescale 1ns / 1ps

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_reset(dut):
    # 100 kHz = 10 µs period
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Assert reset
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 5)

    # Release reset
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    # After reset, outputs should be 0
    assert dut.uo_out.value == 0
    assert dut.uio_out.value == 0
