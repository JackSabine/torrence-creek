module cache import torrence_params::*; #(
    parameter LINE_SIZE = 32, // 32 Bytes per block
    parameter CACHE_SIZE = 1024, // Bytes
    parameter XLEN = 32, // bits

    parameter READ_ONLY = 0,
    parameter FIXED_OP_SIZE = 0,
    parameter ASSOC = 1
) (
    input wire clk,
    reset_if rst_if,
    memory_if.server req_if,
    memory_if.requester hmem_if,
    cache_performance_if.server perf_if
);

cache_internal_if internal_if();

cache_datapath #(
    .LINE_SIZE(LINE_SIZE),
    .CACHE_SIZE(CACHE_SIZE),
    .XLEN(XLEN),
    .READ_ONLY(READ_ONLY),
    .FIXED_OP_SIZE(FIXED_OP_SIZE),
    .ASSOC(ASSOC)
) datapath (.*);

cache_controller controller (.*);

endmodule
