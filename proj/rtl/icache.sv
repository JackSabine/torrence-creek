module icache import torrence_types::*; #(
    parameter LINE_SIZE = 32, // 32 Bytes per block
    parameter CACHE_SIZE = 1024, // Bytes
    parameter XLEN = 32 // bits
) (
    input wire clk,
    reset_if rst_if,
    cache_if.cache req_if,
    higher_memory_if hmem_if
);

///////////////////////////////////////////////////////////////////
//                 controller <-> datapath signals               //
///////////////////////////////////////////////////////////////////
wire miss_recovery_mode;
wire perform_write;
wire clear_selected_valid_bit;
wire finish_new_line_install;
wire set_hmem_block_address;
wire reset_counter;
wire decrement_counter;
wire counter_done;
wire valid_block_match;

cache_datapath #(
    .LINE_SIZE(LINE_SIZE),
    .CACHE_SIZE(CACHE_SIZE),
    .XLEN(XLEN),
    .READ_ONLY(1)
) datapath (
    .clk(clk),
    .rst_if(rst_if),
    .req_if(req_if),
    .hmem_if(hmem_if),

    .miss_recovery_mode(miss_recovery_mode),
    .clear_selected_dirty_bit(),
    .set_selected_dirty_bit(),
    .perform_write(perform_write),
    .clear_selected_valid_bit(clear_selected_valid_bit),
    .finish_new_line_install(finish_new_line_install),
    .set_hmem_block_address(set_hmem_block_address),
    .use_victim_tag_for_hmem_block_address(),
    .reset_counter(reset_counter),
    .decrement_counter(decrement_counter),

    .counter_done(counter_done),
    .valid_block_match(valid_block_match),
    .valid_dirty_bit()
);

cache_controller controller (
    .clk(clk),
    .rst_if(rst_if),
    .req_if(req_if),
    .hmem_if(hmem_if),

    .counter_done(counter_done),
    .valid_block_match(valid_block_match),
    .valid_dirty_bit(1'b0),

    .miss_recovery_mode(miss_recovery_mode),
    .clear_selected_dirty_bit(),
    .set_selected_dirty_bit(),
    .perform_write(perform_write),
    .clear_selected_valid_bit(clear_selected_valid_bit),
    .finish_new_line_install(finish_new_line_install),
    .set_hmem_block_address(set_hmem_block_address),
    .use_victim_tag_for_hmem_block_address(),
    .reset_counter(reset_counter),
    .decrement_counter(decrement_counter)
);

endmodule