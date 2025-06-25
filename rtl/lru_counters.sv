module lru_counters #(
    parameter NUM_SETS = 1,
    parameter ASSOC = 1
) (
    clk,
    reset,
    set,
    selected_way,
    process_lru_counters,
    victim_way
);

localparam SET_SIZE = $clog2(NUM_SETS);
localparam ASSOC_SIZE = $clog2(ASSOC);

input wire clk;
input wire reset;
input wire [SET_SIZE-1:0] set;
input wire [ASSOC_SIZE-1:0] selected_way;
input wire process_lru_counters;
output wire [ASSOC_SIZE-1:0] victim_way;

generate;
    if (ASSOC <= 1) $error("ASSOC (", ASSOC, ") SHALL BE LARGER THAN 1");
    if (ASSOC % 2 != 0) $error("ASSOC (", ASSOC, ") SHALL BE DIVISIBLE BY 2");
endgenerate

logic [NUM_SETS-1:0][ASSOC-1:0][ASSOC_SIZE-1:0] lru_array;
wire [ASSOC_SIZE-1:0] selected_way_lru_counter;

logic [ASSOC-1:0] one_hot_victim_way;

//// Counter reset and increment logic ////
always_ff @(posedge clk) begin
    if (reset) begin
        for (int s = 0; s < NUM_SETS; s++) begin
            for (int w = 0; w < ASSOC; w++) begin
                lru_array[s][w] <= ASSOC_SIZE'(w);
            end
        end
    end else begin
        if (process_lru_counters) begin
            for (int i = 0; i < ASSOC; i++) begin
                unique0 if (selected_way_lru_counter > lru_array[set][i]) begin
                    lru_array[set][i] <= lru_array[set][i] + 1;
                end else if (selected_way == i) begin
                    lru_array[set][i] <= '0;
                end
            end
        end
    end
end

assign selected_way_lru_counter = lru_array[set][selected_way];

//// Victim way identifier logic ////
always_comb begin
    for (int i = 0; i < ASSOC; i++) begin
        one_hot_victim_way[i] = (lru_array[set][i] == '1);
    end
end

NO_MORE_THAN_ONE_WAY_IS_LRU: assert property (
    @(negedge clk) disable iff (reset || $isunknown(set))
    $onehot(one_hot_victim_way)
);

onehot0_to_binary #(
    .ONEHOT_WIDTH(ASSOC)
) victim_way_converter (
    .onehot0(one_hot_victim_way),
    .binary(victim_way)
);

endmodule
