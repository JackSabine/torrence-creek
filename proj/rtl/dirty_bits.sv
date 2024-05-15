module dirty_bits #(
    parameter NUM_SETS = 1,
    parameter ASSOC = 1
) (
    clk,
    set,
    way,
    clear_selected_dirty_bit,
    set_selected_dirty_bit,
    selected_dirty_bit
);

localparam SET_SIZE = $clog2(NUM_SETS);
localparam ASSOC_SIZE = $clog2(ASSOC);

input wire clk;
input wire [SET_SIZE-1:0] set;
input wire [ASSOC_SIZE-1:0] way;
input wire clear_selected_dirty_bit;
input wire set_selected_dirty_bit;
output wire selected_dirty_bit;

logic [NUM_SETS-1:0][ASSOC-1:0] dirty_array;

always_ff @(posedge clk) begin
    unique0 if (clear_selected_dirty_bit) begin
        dirty_array[set][way] <= 1'b0;
    end else if (set_selected_dirty_bit) begin
        dirty_array[set][way] <= 1'b1;
    end
end

assign selected_dirty_bit = (dirty_array[set][way]);

endmodule
