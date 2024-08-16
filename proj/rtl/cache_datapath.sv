`include "macros.svh"

module cache_datapath import torrence_types::*; #(
    parameter LINE_SIZE = 32, // 32 Bytes per block
    parameter CACHE_SIZE = 1024,
    parameter XLEN = 32,

    parameter READ_ONLY = 0,
    parameter ASSOC = 1
) (
    //// TOP LEVEL ////
    input wire clk,
    reset_if rst_if,

    memory_if.server req_if,
    memory_if.requester hmem_if,

    cache_internal_if.datapath internal_if,

    cache_performance_if.server perf_if
);

generate;
    if ((LINE_SIZE % 4 != 0)  || (CACHE_SIZE % 4 != 0)) $error("LINE_SIZE (", LINE_SIZE, ") and CACHE_SIZE (", CACHE_SIZE, ") MUST BE DIVISIBLE BY 4");
    if (LINE_SIZE > CACHE_SIZE) $error("LINE_SIZE (", LINE_SIZE, ") MAY NOT EXCEED CACHE_SIZE (", CACHE_SIZE, ")");
    if (XLEN != `WORD) $error("XLEN VALUES OTHER THAN `WORD (", `WORD, ") ARE NOT SUPPORTED", );
endgenerate

///////////////////////////////////////////////////////////////////
//                        Setup variables                        //
///////////////////////////////////////////////////////////////////
localparam NUM_SETS = CACHE_SIZE / (LINE_SIZE * ASSOC);

localparam OFS_SIZE = $clog2(LINE_SIZE),
           SET_SIZE = $clog2(NUM_SETS),
           TAG_SIZE = XLEN - (SET_SIZE + OFS_SIZE);

localparam WORDS_PER_LINE = LINE_SIZE / `BYTES_PER_WORD;
localparam BYTE_SELECT_SIZE = $clog2(`BYTES_PER_WORD);
localparam WORD_SELECT_SIZE = OFS_SIZE - BYTE_SELECT_SIZE;

localparam ASSOC_WIDTH = $clog2(ASSOC);

///////////////////////////////////////////////////////////////////
//                   Implementation structures                   //
///////////////////////////////////////////////////////////////////
wire [WORD_SELECT_SIZE-1:0] req_word_select, word_select;
wire [BYTE_SELECT_SIZE-1:0] req_byte_select, byte_select;
wire memory_operation_size_e op_size;

logic [XLEN-OFS_SIZE-1:0] hmem_block_address;

wire [XLEN-1:0] word_to_store;

wire [SET_SIZE-1:0] req_set;
wire [TAG_SIZE-1:0] req_tag;

wire [XLEN-1:0] fetched_word;

wire [WORD_SELECT_SIZE-1:0] counter_out;

wire [TAG_SIZE-1:0] selected_tag;

wire [ASSOC_WIDTH-1:0] selected_way;

///////////////////////////////////////////////////////////////////
//                        Steering logic                         //
///////////////////////////////////////////////////////////////////
assign {req_tag, req_set, req_word_select, req_byte_select} = req_if.req_address;

assign word_select   = internal_if.miss_recovery_mode ? counter_out             : req_word_select;
assign byte_select   = internal_if.miss_recovery_mode ? '0                      : req_byte_select;
assign word_to_store = internal_if.miss_recovery_mode ? hmem_if.req_loaded_word : req_if.req_store_word;
assign op_size       = internal_if.miss_recovery_mode ? WORD                    : req_if.req_size;

///////////////////////////////////////////////////////////////////
//                  Higher cache address logic                   //
///////////////////////////////////////////////////////////////////
generate
    if (READ_ONLY == 0) begin
        always_ff @(posedge clk) begin
            if (internal_if.set_hmem_block_address) begin
                hmem_block_address <= {
                    internal_if.use_victim_tag_for_hmem_block_address ? selected_tag : req_tag,
                    req_set
                };
            end
        end
    end else begin
        always_ff @(posedge clk) begin
            if (internal_if.set_hmem_block_address) begin
                hmem_block_address <= {req_tag, req_set};
            end
        end
    end
endgenerate

assign hmem_if.req_address = {hmem_block_address, counter_out, {BYTE_SELECT_SIZE{1'b0}}};

metadata #(
    .NUM_SETS(NUM_SETS),
    .SET_SIZE(SET_SIZE),
    .TAG_SIZE(TAG_SIZE),
    .READ_ONLY(READ_ONLY),
    .ASSOC(ASSOC)
) metadata (
    .clk(clk),
    .reset(rst_if.reset),
    .set(req_set),
    .tag(req_tag),
    .miss_recovery_mode(internal_if.miss_recovery_mode),
    .process_lru_counters(internal_if.process_lru_counters),
    .clear_selected_valid_bit(internal_if.clear_selected_valid_bit),
    .finish_new_line_install(internal_if.finish_new_line_install),
    .clear_selected_dirty_bit(internal_if.clear_selected_dirty_bit),
    .set_selected_dirty_bit(internal_if.set_selected_dirty_bit),

    .valid_dirty_bit(internal_if.valid_dirty_bit),
    .valid_block_match(internal_if.valid_block_match),
    .selected_tag(selected_tag),
    .selected_way(selected_way)
);

datalines #(
    .XLEN(XLEN),
    .NUM_SETS(NUM_SETS),
    .SET_SIZE(SET_SIZE),
    .WORDS_PER_LINE(WORDS_PER_LINE),
    .WORD_SELECT_SIZE(WORD_SELECT_SIZE),
    .BYTE_SELECT_SIZE(BYTE_SELECT_SIZE),
    .ASSOC(ASSOC)
) data (
    .clk(clk),
    .set(req_set),
    .perform_write(internal_if.perform_write),
    .op_size(op_size),
    .word_select(word_select),
    .byte_select(byte_select),
    .selected_way(selected_way),

    .word_to_store(word_to_store),
    .fetched_word(fetched_word)
);

counter #(
    .WIDTH(WORD_SELECT_SIZE),
    .COUNT_UP(0),
    .CHECK_FOR_DONE(1)
) count (
    .clk(clk),
    .reset(internal_if.reset_counter),
    .counter_tick(internal_if.decrement_counter),
    .done(internal_if.counter_done),
    .count(counter_out)
);

assign req_if.req_loaded_word = fetched_word;
assign hmem_if.req_store_word = fetched_word;

perf_counters #(
    .COUNTER_WIDTHS(XLEN)
) perf (
    .clk(clk),
    .reset(rst_if.reset),
    .count_hit(internal_if.count_hit),
    .count_miss(internal_if.count_miss),
    .count_read(internal_if.count_read),
    .count_write(internal_if.count_write),
    .count_writeback(internal_if.count_writeback),
    .hit_value(perf_if.hit_value),
    .miss_value(perf_if.miss_value),
    .read_value(perf_if.read_value),
    .write_value(perf_if.write_value),
    .writeback_value(perf_if.writeback_value)
);

endmodule
