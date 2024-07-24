interface higher_memory_if import torrence_types::*; #(
    parameter XLEN = 32
) (
    input bit clk
);
    logic [XLEN-1:0] req_address;
    memory_operation_e req_operation;
    logic [XLEN-1:0] req_store_word;
    logic req_valid;

    logic [XLEN-1:0] req_loaded_word;
    logic req_fulfilled;
endinterface
