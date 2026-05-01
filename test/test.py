# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


async def send_byte(dut, byte):
    """Send one data byte to the triangle receiver via ui_in/uio_in[0]."""
    dut.ui_in.value = byte
    dut.uio_in.value = 1        # valid high for one cycle
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0        # valid low
    await ClockCycles(dut.clk, 1)


async def send_triangle(dut, x0, y0, x1, y1, x2, y2, color):
    for b in [x0, y0, x1, y1, x2, y2, color]:
        await send_byte(dut, b)


@cocotb.test()
async def test_reset(dut):
    """After reset, outputs should be defined and low."""
    clock = Clock(dut.clk, 40, units="ns")   # 25 MHz
    cocotb.start_soon(clock.start())

    dut.ena.value   = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # All outputs must be 0 (no active pixel, no color) right after reset
    assert dut.uo_out.value == 0, f"Expected 0 after reset, got {dut.uo_out.value}"


@cocotb.test()
async def test_vga_timing(dut):
    """hsync should toggle within one line period (800 cycles at 25 MHz)."""
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value    = 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value  = 1

    # Capture hsync bit (uo_out[0]) over 900 cycles; it must not stay constant
    hsync_vals = set()
    for _ in range(900):
        await RisingEdge(dut.clk)
        hsync_vals.add(int(dut.uo_out.value) & 0x01)

    assert len(hsync_vals) == 2, "hsync did not toggle — VGA timing not running"


@cocotb.test()
async def test_triangle_send(dut):
    """Send a triangle and verify a pixel lights up within one frame."""
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value    = 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value  = 1

    # Triangle: (10,10), (200,10), (100,200), color = white (0xFC)
    await send_triangle(dut, 10, 10, 200, 10, 100, 200, 0xFC)

    # Wait for triangle_setup to finish (needs ~20 cycles) then one full frame
    # Full frame = 800 * 525 = 420000 cycles
    FRAME = 800 * 525
    lit_pixel_seen = False
    for _ in range(FRAME):
        await RisingEdge(dut.clk)
        out = int(dut.uo_out.value)
        color_bits = out & 0b11101110   # mask out hsync/vsync
        if color_bits != 0:
            lit_pixel_seen = True
            break

    assert lit_pixel_seen, "No lit pixel observed within one frame after sending triangle"
