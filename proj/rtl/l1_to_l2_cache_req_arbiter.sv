module l1_to_l2_cache_req_arbiter import torrence_types::*; #(
    parameter XLEN = 32
) (
    input wire clk,
    input wire reset,

    memory_if.server icache_if,
    memory_if.server dcache_if,
    memory_if.requester l2_if
);

typedef enum logic[1:0] {
    ST_IDLE = 2'b00,
    ST_SERVING_ICACHE = 2'b10,
    ST_SERVING_DCACHE = 2'b11,
    ST_UNKNOWN = 2'bxx
} arbiter_state_e;

arbiter_state_e state, next_state;

logic serve_icache;

always_comb begin
    serve_icache = 1'b0;

    case (state)
        ST_IDLE: begin
            priority if (icache_if.req_valid) begin
                next_state = ST_SERVING_ICACHE;
                serve_icache = 1'b1;
            end else if (dcache_if.req_valid) begin
                next_state = ST_SERVING_DCACHE;
            end else begin
                next_state = ST_IDLE;
            end
        end

        ST_SERVING_ICACHE: begin
            serve_icache = 1'b1;
            if (icache_if.req_valid) begin
                next_state = ST_SERVING_ICACHE;
            end else begin
                next_state = ST_IDLE;
            end
        end

        ST_SERVING_DCACHE: begin
            if (dcache_if.req_valid) begin
                next_state = ST_SERVING_DCACHE;
            end else begin
                next_state = ST_IDLE;
            end
        end

        default: begin
            next_state = ST_UNKNOWN;
            serve_icache = 1'bx;
        end
    endcase
end

// Signals to pass up (to L1 caches)
assign icache_if.req_loaded_word = l2_if.req_loaded_word;
assign dcache_if.req_loaded_word = l2_if.req_loaded_word;

assign icache_if.req_fulfilled = ( serve_icache) & l2_if.req_fulfilled;
assign dcache_if.req_fulfilled = (~serve_icache) & l2_if.req_fulfilled;

// Signals to pass down (to higher memory)
assign l2_if.req_address    = serve_icache ? icache_if.req_address : dcache_if.req_address;
assign l2_if.req_operation  = serve_icache ? LOAD                  : dcache_if.req_operation;
assign l2_if.req_store_word = serve_icache ? '0                    : dcache_if.req_store_word;
assign l2_if.req_valid      = serve_icache ? icache_if.req_valid   : dcache_if.req_valid;

//// STATE REGISTER ////
always_ff @(posedge clk) begin
    if (reset) begin
        state <= ST_IDLE;
    end else begin
        state <= next_state;
    end
end

endmodule