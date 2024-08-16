module perf_counters #(
    parameter COUNTER_WIDTHS = 32
) (
    input wire clk,
    input wire reset,
    input wire count_hit,
    input wire count_miss,
    input wire count_read,
    input wire count_write,
    input wire count_writeback,
    output wire [COUNTER_WIDTHS-1:0] hit_value,
    output wire [COUNTER_WIDTHS-1:0] miss_value,
    output wire [COUNTER_WIDTHS-1:0] read_value,
    output wire [COUNTER_WIDTHS-1:0] write_value,
    output wire [COUNTER_WIDTHS-1:0] writeback_value
);

localparam NUM_COUNTERS = 5; //  hits, misses, reads, writes, writebacks (msb to lsb)

wire [NUM_COUNTERS-1:0] count_controls;
wire [NUM_COUNTERS-1:0][COUNTER_WIDTHS-1:0] count_values;

assign count_controls = {count_hit, count_miss, count_read, count_write, count_writeback};
assign {hit_value, miss_value, read_value, write_value, writeback_value} = count_values;

genvar i;

generate;
    for (i = 0; i < NUM_COUNTERS; i = i + 1) begin
        counter #(
            .WIDTH(COUNTER_WIDTHS),
            .COUNT_UP(1),
            .CHECK_FOR_DONE(0)
        ) counter_i (
            .clk(clk),
            .reset(reset),
            .counter_tick(count_controls[i]),
            .done(),
            .count(count_values[i])
        );
    end
endgenerate


endmodule
