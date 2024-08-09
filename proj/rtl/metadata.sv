module metadata #(
    parameter NUM_SETS = 4,
    parameter SET_SIZE = 2,
    parameter TAG_SIZE = 30,

    parameter READ_ONLY = 0,
    parameter ASSOC = 1,

    parameter ASSOC_WIDTH = $clog2(ASSOC)
) (
    input wire clk,
    input wire reset,
    input wire [SET_SIZE-1:0] set,
    input wire [TAG_SIZE-1:0] tag,

    input wire miss_recovery_mode,
    input wire process_lru_counters,

    input wire clear_selected_valid_bit,
    input wire finish_new_line_install,
    input wire clear_selected_dirty_bit,
    input wire set_selected_dirty_bit,

    output wire valid_dirty_bit,
    output wire valid_block_match,
    output wire [TAG_SIZE-1:0] selected_tag,
    output wire [ASSOC_WIDTH-1:0] selected_way
);

logic [NUM_SETS-1:0][ASSOC-1:0] valid_array;
logic [NUM_SETS-1:0][ASSOC-1:0][TAG_SIZE-1:0] tag_array;

logic [ASSOC-1:0] tag_comparisons;
logic [ASSOC-1:0] one_hot_valid_block_matches;

always_ff @(posedge clk) begin
    if (reset) begin
        valid_array <= '0;
    end else begin
        unique0 if (clear_selected_valid_bit) begin
            valid_array[set][selected_way] <= 1'b0;
        end else if (finish_new_line_install) begin
            valid_array[set][selected_way] <= 1'b1;
            tag_array[set][selected_way] <= tag;
        end
    end
end

always_comb begin
    for (int i = 0; i < ASSOC; i++) begin
        tag_comparisons[i] = (tag_array[set][i] == tag);

        one_hot_valid_block_matches[i] = (valid_array[set][i] & tag_comparisons[i]);
    end
end

assign valid_block_match = |one_hot_valid_block_matches;

generate;
    if (READ_ONLY == 0) begin
        wire selected_dirty_bit;

        dirty_bits #(
            .NUM_SETS(NUM_SETS),
            .ASSOC(ASSOC)
        ) dirty_bits (
            .clk(clk),
            .set(set),
            .way(selected_way),
            .clear_selected_dirty_bit(clear_selected_dirty_bit),
            .set_selected_dirty_bit(set_selected_dirty_bit),
            .selected_dirty_bit(selected_dirty_bit)
        );

        assign valid_dirty_bit = (valid_array[set][selected_way] & selected_dirty_bit);
    end else begin
        assign valid_dirty_bit = 1'b0;
    end

    if (ASSOC > 1) begin
        wire [ASSOC_WIDTH-1:0] matching_way;
        wire [ASSOC_WIDTH-1:0] victim_way;

        lru_counters #(
            .NUM_SETS(NUM_SETS),
            .ASSOC(ASSOC)
        ) lru_counters (
            .clk(clk),
            .reset(reset),
            .set(set),
            .selected_way(selected_way),
            .process_lru_counters(process_lru_counters),
            .victim_way(victim_way)
        );

        NO_MORE_THAN_ONE_BLOCK_MATCH: assert property (
            @(negedge clk) disable iff (reset || $isunknown(set))
            $onehot0(one_hot_valid_block_matches)
        );

        onehot0_to_binary #(
            .ONEHOT_WIDTH(ASSOC)
        ) matching_block_converter (
            .onehot0(one_hot_valid_block_matches),
            .binary(matching_way)
        );

        assign selected_way = (miss_recovery_mode) ? victim_way : matching_way;
    end else begin
        assign selected_way = 1'b0;
    end
endgenerate

assign selected_tag = (tag_array[set][selected_way]);

endmodule
