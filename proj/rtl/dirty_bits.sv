module dirty_bits #(
    parameter NUM_SETS = 1
) (
    clk,
    set,
    clear_selected_dirty_bit,
    set_selected_dirty_bit,
    selected_dirty_bit
);

localparam SET_SIZE = $clog2(NUM_SETS);

input wire clk;
input wire [SET_SIZE-1:0] set;
input wire clear_selected_dirty_bit;
input wire set_selected_dirty_bit;
output wire selected_dirty_bit;

logic [NUM_SETS-1:0] dirty_array;

always_ff @(posedge clk) begin
    unique0 if (clear_selected_dirty_bit) begin
        dirty_array[set] <= 1'b0;
    end else if (set_selected_dirty_bit) begin
        dirty_array[set] <= 1'b1;
    end
end

assign selected_dirty_bit = (dirty_array[set]);

endmodule
