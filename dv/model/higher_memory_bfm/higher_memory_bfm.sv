`include "uvm_macros.svh"

module higher_memory_bfm #(
    parameter XLEN = 32
) (
    input logic clk,
    input logic rst,
    memory_if hmem_if
);

import torrence_pkg::*;
import torrence_params::*;
import uvm_pkg::*;

main_memory dut_memory_model;
bit initialized = 1'b0;

initial begin
    uvm_config_db #(main_memory)::wait_modified(
        .cntxt(uvm_root::get()),
        .inst_name(""),
        .field_name("dut_memory_model")
    );

    assert(uvm_config_db #(main_memory)::get(
        .cntxt(uvm_root::get()),
        .inst_name(""),
        .field_name("dut_memory_model"),
        .value(dut_memory_model)
    )) else `uvm_fatal("higher_memory_bfm", "Couldn't get dut_memory_model from config db")

    `uvm_info(
        "higher_memory_bfm",
        "Higher memory BFM initialized and connected to DUT memory model",
        UVM_LOW
    )

    initialized = 1'b1;
end

always @(hmem_if.req_valid or hmem_if.req_address or hmem_if.req_size) begin
    if (rst) begin
        hmem_if.req_loaded_word = '0;
    end else if (initialized && hmem_if.req_valid) begin
        hmem_if.req_loaded_word = dut_memory_model.tb_read(hmem_if.req_address, hmem_if.req_size).req_word;
    end
end

always @(posedge clk) begin
    if (initialized) begin
        if (hmem_if.req_fulfilled) begin
            case (hmem_if.req_operation)
                LOAD:  void'(dut_memory_model.read(hmem_if.req_address, hmem_if.req_size));
                STORE: void'(dut_memory_model.write(hmem_if.req_address, hmem_if.req_size, hmem_if.req_store_word));
                default: begin end
            endcase
        end
    end
end

logic rng_allow_fulfilled;
int rng;

always_ff @(posedge clk) begin
    rng = $urandom_range(0, 100);
end

always_comb begin
    if (rst) begin
        rng_allow_fulfilled = 1'b0;
    end else begin
        if (rng < 80) begin
            rng_allow_fulfilled = 1'b1;
        end else begin
            rng_allow_fulfilled = 1'b0;
        end
    end
end

assign hmem_if.req_fulfilled = !rst && hmem_if.req_valid && rng_allow_fulfilled;

endmodule
