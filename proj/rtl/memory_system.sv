module memory_system #(
    parameter XLEN = 32,
    parameter LINE_SIZE = 32,
    parameter ICACHE_SIZE = 1024,
    parameter DCACHE_SIZE = 1024,
    parameter L2_SIZE = 4096,
    parameter L2_ASSOC = 4
) (
    input wire clk,
    reset_if rst_if,
    memory_if.server icache_req_if,
    memory_if.server dcache_req_if,
    memory_if.requester hmem_if
);

memory_if icache_rsp_if(clk);
memory_if dcache_rsp_if(clk);

cache #(
    .LINE_SIZE(LINE_SIZE),
    .CACHE_SIZE(ICACHE_SIZE),
    .XLEN(XLEN),

    .READ_ONLY(1)
) icache (
    .clk(clk),
    .rst_if(rst_if),
    .req_if(icache_req_if),
    .hmem_if(icache_rsp_if)
);

cache #(
    .LINE_SIZE(LINE_SIZE),
    .CACHE_SIZE(DCACHE_SIZE),
    .XLEN(XLEN),

    .READ_ONLY(0)
) dcache (
    .clk(clk),
    .rst_if(rst_if),
    .req_if(dcache_req_if),
    .hmem_if(dcache_rsp_if)
);

l1_to_l2_cache_req_arbiter #(
    .XLEN(XLEN)
) l1_to_l2_cache_req_arbiter (
    .clk(clk),
    .reset(rst_if.reset),
    .icache_if(icache_rsp_if),
    .dcache_if(dcache_rsp_if),
    .l2_if(hmem_if)
);

endmodule
