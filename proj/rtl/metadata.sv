module metadata #(
    parameter NUM_SETS = 4,
    parameter SET_SIZE = 2,
    parameter TAG_SIZE = 30,

    parameter READ_ONLY = 0
) (
    input wire clk,
    input wire reset,
    input wire [SET_SIZE-1:0] set,
    input wire [TAG_SIZE-1:0] tag,

    input wire clear_selected_valid_bit,
    input wire finish_new_line_install,
    input wire clear_selected_dirty_bit,
    input wire set_selected_dirty_bit,

    output wire valid_dirty_bit,
    output wire valid_block_match,
    output wire [TAG_SIZE-1:0] selected_tag
);

logic [NUM_SETS-1:0] valid_array;
logic [NUM_SETS-1:0][TAG_SIZE-1:0] tag_array;

wire tag_match;

generate
    if (READ_ONLY == 0) begin
        wire selected_dirty_bit;

        dirty_bits #(
            .NUM_SETS(NUM_SETS)
        ) dirty_bits (
            .clk(clk),
            .set(set),
            .clear_selected_dirty_bit(clear_selected_dirty_bit),
            .set_selected_dirty_bit(set_selected_dirty_bit),
            .selected_dirty_bit(selected_dirty_bit)
        );

        assign valid_dirty_bit = (valid_array[set] & selected_dirty_bit);
    end else begin
        assign valid_dirty_bit = 1'b0;
    end
endgenerate

always_ff @(posedge clk) begin
    if (reset) begin
        valid_array <= '0;
    end else begin
        unique0 if (clear_selected_valid_bit) begin
            valid_array[set] <= 1'b0;
        end else if (finish_new_line_install) begin
            valid_array[set] <= 1'b1;
            tag_array[set] <= tag;
        end
    end
end

assign tag_match         = (tag_array[set] == tag);
assign valid_block_match = (valid_array[set] & tag_match);
assign selected_tag      = (tag_array[set]);

endmodule
