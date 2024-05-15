`include "macros.svh"

module datalines import torrence_types::*; #(
    parameter XLEN = 32,
    parameter NUM_SETS = 4,
    parameter SET_SIZE = 2,
    parameter WORDS_PER_LINE = 8,
    parameter WORD_SELECT_SIZE = 2,
    parameter BYTE_SELECT_SIZE = 2,
    parameter ASSOC = 1,
    parameter ASSOC_WIDTH = $clog2(ASSOC)
) (
    input wire clk,

    input wire perform_write,

    input wire [SET_SIZE-1:0] set,
    input wire memory_operation_size_e op_size,
    input wire [WORD_SELECT_SIZE-1:0] word_select,
    input wire [BYTE_SELECT_SIZE-1:0] byte_select,
    input wire [ASSOC_WIDTH-1:0] selected_way,

    input wire [XLEN-1:0] word_to_store,
    output logic [XLEN-1:0] fetched_word
);

logic [NUM_SETS-1:0][ASSOC-1:0][WORDS_PER_LINE-1:0][`BYTES_PER_WORD-1:0][`BYTE-1:0] data_lines;

logic [`BYTE-1:0] byte_read;
logic [`HALF-1:0] half_read;
logic [`WORD-1:0] word_read;

logic [ASSOC-1:0][`WORD-1:0] words_read;

logic [NUM_SETS-1:0]       w_set_active;
logic [ASSOC-1:0]          w_way_active;
logic [WORDS_PER_LINE-1:0] w_word_active;
logic [`BYTES_PER_WORD-1:0] w_byte_active;
logic [`BYTES_PER_WORD-1:0][`BYTE-1:0] write_bus;


always_comb begin : read_logic
    for (int i = 0; i < ASSOC; i++) begin
        words_read[i] = data_lines[set][i][word_select];
    end

    word_read = words_read[selected_way];

    byte_read = word_read[byte_select*`BYTE +: `BYTE];
    half_read = word_read[byte_select[1]*`HALF +: `HALF];

    case (op_size)
        BYTE:    fetched_word = {'0, byte_read};
        HALF:    fetched_word = {'0, half_read};
        WORD:    fetched_word = {'0, word_read};
        default: fetched_word = 'x;
    endcase
end


always_comb begin : write_matrix_logic
    for (int i_set = 0; i_set < NUM_SETS; i_set = i_set + 1) begin
        w_set_active[i_set] = set == i_set;
    end

    for (int i_way = 0; i_way < ASSOC; i_way++) begin
        w_way_active[i_way] = (selected_way == i_way);
    end

    for (int i_word = 0; i_word < WORDS_PER_LINE; i_word = i_word + 1) begin
        w_word_active[i_word] = word_select == i_word;
    end

    case (op_size)
        BYTE:    w_byte_active = (4'b0001 << byte_select);
        HALF:    w_byte_active = (4'b0011 << {byte_select[1], 1'b0});
        WORD:    w_byte_active = (4'b1111);
        default: w_byte_active = 'x;
    endcase
end


always_comb begin : write_bus_logic
    unique casez (op_size)
        BYTE:    write_bus = {`BYTES_PER_WORD{word_to_store[`BYTE-1:0]}};
        HALF:    write_bus = {`HALFS_PER_WORD{word_to_store[`HALF-1:0]}};
        WORD:    write_bus = word_to_store;
        default: write_bus = 'x;
    endcase
end


always_ff @(posedge clk) begin
    for (int s = 0; s < NUM_SETS; s++) begin
        for (int way = 0; way < ASSOC; way++) begin
            for (int w = 0; w < WORDS_PER_LINE; w++) begin
                for (int b = 0; b < `BYTES_PER_WORD; b++) begin
                    if (perform_write & w_set_active[s] & w_way_active[way] & w_word_active[w] & w_byte_active[b]) begin
                        data_lines[s][way][w][b] <= write_bus[b];
                    end
                end
            end
        end
    end
end

endmodule