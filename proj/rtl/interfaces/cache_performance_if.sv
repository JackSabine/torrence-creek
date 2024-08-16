interface cache_performance_if #(
    parameter XLEN = 32
) (
    input bit clk
);
    logic [XLEN-1:0] hit_value;
    logic [XLEN-1:0] miss_value;
    logic [XLEN-1:0] read_value;
    logic [XLEN-1:0] write_value;
    logic [XLEN-1:0] writeback_value;

    modport server (
        output hit_value, miss_value, read_value, write_value, writeback_value
    );

    modport requester (
        input hit_value, miss_value, read_value, write_value, writeback_value
    );
endinterface