![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Hardware Triangle Rasterizer with VGA Output

A hardware triangle rasterizer implemented in SystemVerilog for the TinyTapeout Sky26a shuttle. Renders filled, colored triangles to a 640×480 @ 25 Hz VGA display using the edge-equation half-plane method with incremental per-pixel evaluation (no multipliers in the render loop).

See [docs/info.md](docs/info.md) for full documentation, pinout, and usage instructions.
