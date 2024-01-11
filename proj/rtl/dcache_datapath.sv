`include "macros.svh"

module dcache_datapath import xentry_pkg::*; #(
    parameter LINE_SIZE = 32, // 32 Bytes per block
    parameter OFS_SIZE = 0,
    parameter SET_SIZE = 0,
    parameter TAG_SIZE = 0,
    parameter NUM_SETS = 0,
    parameter XLEN = 32
) (
    //// TOP LEVEL ////
    input wire clk,
    input wire reset,

    //// PIPELINE ////
    input wire [OFS_SIZE-1:0] pipe_req_ofs,
    input wire [SET_SIZE-1:0] pipe_req_set,
    input wire [TAG_SIZE-1:0] pipe_req_tag,
    input wire memory_operation_size_e pipe_req_size,
    input wire memory_operation_e pipe_req_type,
    input wire pipe_req_valid,
    input wire [XLEN-1:0] pipe_word_to_store,
    output logic [XLEN-1:0] pipe_fetched_word,

    //// HIGHER MEMORY ////
    output wire [XLEN-1:0] l2_req_address,
    input wire [XLEN-1:0] l2_fetched_word,
    output logic [XLEN-1:0] l2_word_to_store,

    //// DATAPATH/CONTROLLER SIGNALS ////
    input wire flush_mode,
    input wire load_mode,
    input wire clear_selected_dirty_bit,
    input wire clear_selected_valid_bit,
    input wire finish_new_line_install,
    input wire set_new_l2_block_address,
    input wire use_dirty_tag_for_l2_block_address,
    input wire reset_counter,
    input wire decrement_counter,

    output wire counter_done,
    output logic hit,
    output logic valid_dirty_bit,
    output logic miss,
    output logic clflush_requested
);

///////////////////////////////////////////////////////////////////
//                        Setup variables                        //
///////////////////////////////////////////////////////////////////
localparam BYTES_PER_WORD = XLEN / 8;
localparam HALFS_PER_WORD = XLEN / 16;
localparam WORDS_PER_LINE = LINE_SIZE / BYTES_PER_WORD;
localparam BYTE_SELECT_SIZE = $clog2(BYTES_PER_WORD);
localparam WORD_SELECT_SIZE = OFS_SIZE - BYTE_SELECT_SIZE;

///////////////////////////////////////////////////////////////////
//                    Cache memory structures                    //
///////////////////////////////////////////////////////////////////
logic [NUM_SETS-1:0] valid_array, dirty_array;
logic [NUM_SETS-1:0][TAG_SIZE-1:0] tag_array;
logic [NUM_SETS-1:0][WORDS_PER_LINE-1:0][BYTES_PER_WORD-1:0][7:0] data_lines;

///////////////////////////////////////////////////////////////////
//                   Implementation structures                   //
///////////////////////////////////////////////////////////////////
logic [WORD_SELECT_SIZE-1:0] counter;

wire [WORD_SELECT_SIZE-1:0] pipe_req_word_select, word_select;
wire [BYTE_SELECT_SIZE-1:0] pipe_req_byte_select, byte_select;
memory_operation_size_e op_size;

logic tag_match;

logic [7:0] byte_read;
logic [15:0] half_read;
logic [31:0] word_read;

logic [WORDS_PER_LINE-1:0][BYTES_PER_WORD-1:0][7:0] selected_data_line;
logic [BYTES_PER_WORD-1:0][7:0] zext_sized_read_data;

logic [31:0] byte_write;
logic [31:0] half_write;
logic [31:0] word_write;

logic [NUM_SETS-1:0] w_set_active;
logic [WORDS_PER_LINE-1:0] w_word_active;
logic [BYTES_PER_WORD-1:0] w_byte_active;
logic [BYTES_PER_WORD-1:0][7:0] write_bus;

logic perform_write;
logic set_selected_dirty_bit;

logic [XLEN-OFS_SIZE-1:0] l2_block_address;

///////////////////////////////////////////////////////////////////
//                        Counter logic                          //
///////////////////////////////////////////////////////////////////
assign counter_done = (counter == 'd0);

always_ff @(posedge clk) begin
    if (reset_counter) begin
        counter <= {WORD_SELECT_SIZE{1'b1}};
    end else if (decrement_counter) begin
        counter <= counter - WORD_SELECT_SIZE'('d1);
    end
end

///////////////////////////////////////////////////////////////////
//                        Steering logic                         //
///////////////////////////////////////////////////////////////////
assign {pipe_req_word_select, pipe_req_byte_select} = pipe_req_ofs;
assign word_select = (flush_mode | load_mode) ? counter : pipe_req_word_select;
assign byte_select = (flush_mode | load_mode) ? '0      : pipe_req_byte_select;

always_comb begin
    if (load_mode || flush_mode) op_size = WORD;
    else                         op_size = pipe_req_size;
end

///////////////////////////////////////////////////////////////////
//                    Cache metadata logic                       //
///////////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if (reset) begin
        for (int i_set = 0; i_set < NUM_SETS; i_set = i_set + 1) begin
            valid_array[i_set] <= 1'b0;
        end
    end else begin
        unique0 if (clear_selected_valid_bit) begin
            valid_array[pipe_req_set] <= 1'b0;
        end else if (finish_new_line_install) begin
            valid_array[pipe_req_set] <= 1'b1;
            tag_array[pipe_req_set] <= pipe_req_tag;
        end

        for (int i_set = 0; i_set < NUM_SETS; i_set = i_set + 1) begin
            if (i_set == pipe_req_set && clear_selected_dirty_bit) begin
                // Clear selected dirty bit with higher priority
                dirty_array[pipe_req_set] <= 1'b0;
            end else if (i_set == pipe_req_set && set_selected_dirty_bit) begin
                // Only set dirty bit if a write active line is high and we aren't loading from L2
                dirty_array[i_set] <= 1'b1;
            end
        end
    end
end

///////////////////////////////////////////////////////////////////
//                       Hit/miss logic                          //
///////////////////////////////////////////////////////////////////
always_comb begin
    {hit, miss} = 2'b00;

    valid_dirty_bit = valid_array[pipe_req_set] & dirty_array[pipe_req_set];
    tag_match = tag_array[pipe_req_set] == pipe_req_tag;

    // tag_match is allowed to be x
    casex({pipe_req_valid, valid_array[pipe_req_set], tag_match})
        3'b0??: begin /* nop */ end
        3'b10?: miss = 1'b1;
        3'b110: miss = 1'b1;
        3'b111: hit = 1'b1;
        default: {hit, miss} = 2'bxx;
    endcase

    clflush_requested = pipe_req_valid & (pipe_req_type == CLFLUSH);
end


///////////////////////////////////////////////////////////////////
//                     Cacheline read logic                      //
///////////////////////////////////////////////////////////////////
always_comb begin
    selected_data_line = data_lines[pipe_req_set];
    word_read = selected_data_line[word_select];

    byte_read = word_read[byte_select*`BYTE +: `BYTE];
    half_read = word_read[byte_select[1]*`HALF +: `HALF];

    case (op_size)
    BYTE: zext_sized_read_data = {'0, byte_read};
    HALF: zext_sized_read_data = {'0, half_read};
    WORD: zext_sized_read_data = {'0, word_read};
    default: zext_sized_read_data = 'x;
    endcase

    pipe_fetched_word = zext_sized_read_data;
    l2_word_to_store = word_read;
end

///////////////////////////////////////////////////////////////////
//                     Cacheline write logic                     //
///////////////////////////////////////////////////////////////////
always_comb begin : w_set_active_logic
    for (int i_set = 0; i_set < NUM_SETS; i_set = i_set + 1) begin
        w_set_active[i_set] = pipe_req_set == i_set;
    end
end

always_comb begin : w_word_active_logic
    for (int i_word = 0; i_word < WORDS_PER_LINE; i_word = i_word + 1) begin
        w_word_active[i_word] = word_select == i_word;
    end
end

always_comb begin : w_byte_active_logic
    // Init condition
    w_byte_active = '0;

    case (op_size)
        BYTE: w_byte_active[byte_select] = 1'b1;

        HALF: unique0 casez (byte_select)
            2'b0?: w_byte_active = 4'b0011;
            2'b1?: w_byte_active = 4'b1100;
        endcase

        WORD: w_byte_active = '1;

        default: w_byte_active = 'x;
    endcase
end

always_comb begin : write_bus_logic
    word_write = load_mode ? l2_fetched_word : pipe_word_to_store;

    byte_write = {BYTES_PER_WORD{word_write[`BYTE-1:0]}};
    half_write = {HALFS_PER_WORD{word_write[`HALF-1:0]}};

    unique casez (op_size)
        BYTE: write_bus = byte_write;
        HALF: write_bus = half_write;
        WORD: write_bus = word_write;
        default: write_bus = 'x;
    endcase
end

always_comb begin : perform_write_logic
    perform_write = (hit & (pipe_req_type == STORE)) | load_mode;
    set_selected_dirty_bit = (hit & (pipe_req_type == STORE)) & !load_mode;
end

always_ff @(posedge clk) begin
    for (int i_set = 0; i_set < NUM_SETS; i_set = i_set + 1) begin
        for (int i_word = 0; i_word < WORDS_PER_LINE; i_word = i_word + 1) begin
            for (int i_byte = 0; i_byte < BYTES_PER_WORD; i_byte = i_byte + 1) begin
                if (perform_write & w_set_active[i_set] & w_word_active[i_word] & w_byte_active[i_byte]) begin
                    data_lines[i_set][i_word][i_byte] <= write_bus[i_byte];
                end
            end
        end
    end
end

///////////////////////////////////////////////////////////////////
//                  Higher cache address logic                   //
///////////////////////////////////////////////////////////////////
always_ff @(posedge clk) begin
    if (set_new_l2_block_address) begin
        l2_block_address <= {
            use_dirty_tag_for_l2_block_address ? tag_array[pipe_req_set] : pipe_req_tag,
            pipe_req_set
        };
    end
end

assign l2_req_address = {l2_block_address, counter, {BYTE_SELECT_SIZE{1'b0}}};

endmodule
