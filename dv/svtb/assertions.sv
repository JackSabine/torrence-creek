`include "uvm_macros.svh"

module lru_counters_assertions import uvm_pkg::*; #(
    parameter SET_SIZE = 1,
    parameter ASSOC = 1
) (
    input logic clk,
    input logic reset,
    input wire [SET_SIZE-1:0] set,
    input logic [ASSOC-1:0] one_hot_victim_way
);

    NO_MORE_THAN_ONE_WAY_IS_LRU: assert property (
        @(negedge clk) disable iff (reset || $isunknown(set))
        $onehot(one_hot_victim_way)
    ) else `uvm_error(
        "NO_MORE_THAN_ONE_WAY_IS_LRU",
        $sformatf("[%m]: No victim way or several victim ways are selected: %b", one_hot_victim_way)
    )
endmodule

bind lru_counters lru_counters_assertions #(.SET_SIZE(SET_SIZE), .ASSOC(ASSOC)) i_lru_counters_assertions (.*);



module metadata_assertions import uvm_pkg::*; #(
    parameter SET_SIZE = 1,
    parameter ASSOC = 1
) (
    input logic clk,
    input logic reset,
    input logic [SET_SIZE-1:0] set,
    input logic [ASSOC-1:0] one_hot_valid_block_matches
);

    NO_MORE_THAN_ONE_BLOCK_MATCH: assert property (
            @(negedge clk) disable iff (reset || $isunknown(set))
            $onehot0(one_hot_valid_block_matches)
    ) else `uvm_error(
        "NO_MORE_THAN_ONE_BLOCK_MATCH",
        $sformatf("[%m]: No block or several blocks are selected: %b", one_hot_valid_block_matches)
    )
endmodule

bind metadata metadata_assertions #(.SET_SIZE(SET_SIZE), .ASSOC(ASSOC)) i_metadata_assertions (.*);
