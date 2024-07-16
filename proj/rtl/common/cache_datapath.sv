`include "macros.svh"

module cache_datapath import torrence_types::*; #(
    parameter LINE_SIZE = 32, // 32 Bytes per block
    parameter CACHE_SIZE = 1024,
    parameter XLEN = 32,

    parameter READ_ONLY = 0
) (
    //// TOP LEVEL ////
    input wire clk,
    reset_if rst_if,

    cache_if req_if,
    higher_memory_if hmem_if,

    //// DATAPATH/CONTROLLER SIGNALS ////
    input wire miss_recovery_mode,
    input wire clear_selected_dirty_bit,
    input wire set_selected_dirty_bit,
    input wire perform_write,
    input wire clear_selected_valid_bit,
    input wire finish_new_line_install,
    input wire set_hmem_block_address,
    input wire use_victim_tag_for_hmem_block_address,
    input wire reset_counter,
    input wire decrement_counter,

    output wire counter_done,
    output logic valid_block_match,
    output logic valid_dirty_bit
);

generate;
    if ((LINE_SIZE % 4 != 0)  || (CACHE_SIZE % 4 != 0)) $error("LINE_SIZE (", LINE_SIZE, ") and CACHE_SIZE (", CACHE_SIZE, ") MUST BE DIVISIBLE BY 4");
    if (LINE_SIZE > CACHE_SIZE) $error("LINE_SIZE (", LINE_SIZE, ") MAY NOT EXCEED CACHE_SIZE (", CACHE_SIZE, ")");
    if (XLEN != `WORD) $error("XLEN VALUES OTHER THAN `WORD (", `WORD, ") ARE NOT SUPPORTED", );
endgenerate

///////////////////////////////////////////////////////////////////
//                        Setup variables                        //
///////////////////////////////////////////////////////////////////
localparam NUM_SETS = CACHE_SIZE / (LINE_SIZE);

localparam OFS_SIZE = $clog2(LINE_SIZE),
           SET_SIZE = $clog2(NUM_SETS),
           TAG_SIZE = XLEN - (SET_SIZE + OFS_SIZE);

localparam WORDS_PER_LINE = LINE_SIZE / `BYTES_PER_WORD;
localparam BYTE_SELECT_SIZE = $clog2(`BYTES_PER_WORD);
localparam WORD_SELECT_SIZE = OFS_SIZE - BYTE_SELECT_SIZE;

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

///////////////////////////////////////////////////////////////////
//                        Steering logic                         //
///////////////////////////////////////////////////////////////////
assign {req_tag, req_set, req_word_select, req_byte_select} = req_if.req_address;

assign word_select   = miss_recovery_mode ? counter_out             : req_word_select;
assign byte_select   = miss_recovery_mode ? '0                      : req_byte_select;
assign word_to_store = miss_recovery_mode ? hmem_if.req_loaded_word : req_if.req_store_word;
assign op_size       = miss_recovery_mode ? WORD                    : req_if.req_size;

///////////////////////////////////////////////////////////////////
//                  Higher cache address logic                   //
///////////////////////////////////////////////////////////////////
generate
    if (READ_ONLY == 0) begin
        always_ff @(posedge clk) begin
            if (set_hmem_block_address) begin
                hmem_block_address <= {
                    use_victim_tag_for_hmem_block_address ? selected_tag : req_tag,
                    req_set
                };
            end
        end
    end else begin
        always_ff @(posedge clk) begin
            if (set_hmem_block_address) begin
                hmem_block_address <= {req_tag, req_set};
            end
        end
    end
endgenerate

assign hmem_if.req_address = {hmem_block_address, counter_out, {BYTE_SELECT_SIZE{1'b0}}};

cache_metadata #(
    .NUM_SETS(NUM_SETS),
    .SET_SIZE(SET_SIZE),
    .TAG_SIZE(TAG_SIZE),
    .READ_ONLY(READ_ONLY)
) metadata (
    .set(req_set),
    .tag(req_tag),
    .reset(rst_if.reset),
    .*
);

cache_data #(
    .XLEN(XLEN),
    .NUM_SETS(NUM_SETS),
    .SET_SIZE(SET_SIZE),
    .WORDS_PER_LINE(WORDS_PER_LINE),
    .WORD_SELECT_SIZE(WORD_SELECT_SIZE),
    .BYTE_SELECT_SIZE(BYTE_SELECT_SIZE)
) data (
    .set(req_set),
    .*
);

counter #(
    .WIDTH(WORD_SELECT_SIZE)
) count (
    .clk(clk),
    .reset(reset_counter),
    .count_down(decrement_counter),
    .done(counter_done),
    .count(counter_out)
);

assign req_if.req_store_word = fetched_word;
assign req_if.fetched_word   = fetched_word;

endmodule
