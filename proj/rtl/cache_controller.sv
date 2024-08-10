module cache_controller import torrence_types::*; (
    //// TOP LEVEL ////
    input wire clk,
    reset_if rst_if,

    memory_if.server req_if,
    memory_if.requester hmem_if,

    cache_internal_if.controller internal_if
);

typedef enum logic[1:0] {
    ST_IDLE = 2'b00,
    ST_FLUSH = 2'b01,
    ST_ALLOCATE = 2'b11,
    ST_WRITEBACK = 2'b10,
    ST_UNKNOWN = 2'bxx
} cache_state_e;

cache_state_e state, next_state, prev_state;

logic mealy_perform_write, moore_perform_write;

assign internal_if.perform_write = mealy_perform_write | moore_perform_write;

//// NEXT STATE LOGIC AND MEALY OUTPUTS ////
always_comb begin
    {
        internal_if.clear_selected_dirty_bit,
        internal_if.set_selected_dirty_bit,
        mealy_perform_write,
        internal_if.clear_selected_valid_bit,
        internal_if.finish_new_line_install,
        internal_if.set_hmem_block_address,
        internal_if.use_victim_tag_for_hmem_block_address,
        internal_if.reset_counter,
        req_if.req_fulfilled,
        internal_if.decrement_counter,
        internal_if.process_lru_counters,
        internal_if.count_hit,
        internal_if.count_miss,
        internal_if.count_read,
        internal_if.count_write
    } = '0;

    case (state)
        ST_IDLE: begin
            if (req_if.req_valid) begin
                if (req_if.req_operation == CLFLUSH) begin
                    unique casez ({internal_if.valid_block_match, internal_if.valid_dirty_bit})
                        2'b0?: begin : clflush_block_not_present
                            next_state = ST_IDLE;
                            req_if.req_fulfilled = 1'b1;
                        end
                        2'b10: begin : clflush_block_present_and_clean
                            next_state = ST_IDLE;
                            internal_if.clear_selected_valid_bit = 1'b1;
                            req_if.req_fulfilled = 1'b1;
                        end
                        2'b11: begin : clflush_block_present_and_dirty
                            next_state = ST_FLUSH;
                            internal_if.use_victim_tag_for_hmem_block_address = 1'b1;
                            internal_if.set_hmem_block_address = 1'b1;
                            internal_if.reset_counter = 1'b1;
                        end
                        default: begin
                            next_state = ST_UNKNOWN;
                        end
                    endcase
                end else begin
                    unique casez ({internal_if.valid_block_match, internal_if.valid_dirty_bit})
                        2'b00: begin : clean_miss
                            next_state = ST_ALLOCATE;
                            internal_if.set_hmem_block_address = 1'b1;
                            internal_if.reset_counter = 1'b1;
                            internal_if.count_miss = 1'b1;
                        end
                        2'b1?: begin : hit
                            next_state = ST_IDLE;
                            req_if.req_fulfilled = 1'b1;
                            internal_if.process_lru_counters = 1'b1;
                            if (req_if.req_operation == STORE) begin
                                mealy_perform_write = 1'b1;
                                internal_if.set_selected_dirty_bit = 1'b1;
                                internal_if.count_write = 1'b1;
                            end else if (req_if.req_operation == LOAD) begin
                                internal_if.count_read = 1'b1;
                            end

                            if (prev_state != ST_ALLOCATE) begin
                                // A hit only counts if we didn't come from ST_ALLOCATE (was a miss when first requested)
                                internal_if.count_hit = 1'b1;
                            end
                        end
                        2'b01: begin : dirty_miss
                            next_state = ST_WRITEBACK;
                            internal_if.use_victim_tag_for_hmem_block_address = 1'b1;
                            internal_if.set_hmem_block_address = 1'b1;
                            internal_if.reset_counter = 1'b1;
                            internal_if.count_miss = 1'b1;
                        end
                        default: begin
                            next_state = ST_UNKNOWN;
                        end
                    endcase
                end
            end else begin
                next_state = ST_IDLE;
            end
        end

        ST_WRITEBACK: begin
            if (internal_if.counter_done & hmem_if.req_fulfilled) begin
                next_state = ST_ALLOCATE;
                internal_if.set_hmem_block_address = 1'b1;
                internal_if.reset_counter = 1'b1;
                internal_if.clear_selected_dirty_bit = 1'b1;
                internal_if.clear_selected_valid_bit = 1'b1;
            end else begin
                next_state = ST_WRITEBACK;
            end

            if (hmem_if.req_fulfilled) begin
                internal_if.decrement_counter = 1'b1;
            end
        end

        ST_ALLOCATE: begin
            if (internal_if.counter_done & hmem_if.req_fulfilled) begin
                next_state = ST_IDLE;
                internal_if.finish_new_line_install = 1'b1;
                internal_if.clear_selected_dirty_bit = 1'b1;
                internal_if.process_lru_counters = 1'b1;
            end else begin
                next_state = ST_ALLOCATE;
            end

            if (hmem_if.req_fulfilled) begin
                internal_if.decrement_counter = 1'b1;
            end
        end

        ST_FLUSH: begin
            if (internal_if.counter_done & hmem_if.req_fulfilled) begin
                next_state = ST_IDLE;
                internal_if.clear_selected_dirty_bit = 1'b1;
                internal_if.clear_selected_valid_bit = 1'b1;
                req_if.req_fulfilled = 1'b1;
            end else begin
                next_state = ST_FLUSH;
            end

            if (hmem_if.req_fulfilled) begin
                internal_if.decrement_counter = 1'b1;
            end
        end

        default: begin
            next_state = ST_UNKNOWN;
            {
                internal_if.clear_selected_dirty_bit,
                internal_if.set_selected_dirty_bit,
                mealy_perform_write,
                internal_if.clear_selected_valid_bit,
                internal_if.finish_new_line_install,
                internal_if.set_hmem_block_address,
                internal_if.use_victim_tag_for_hmem_block_address,
                internal_if.reset_counter,
                req_if.req_fulfilled,
                internal_if.decrement_counter,
                internal_if.process_lru_counters
            } = 'x;
        end
    endcase
end

//// MOORE OUTPUTS ////
always_comb begin
    internal_if.miss_recovery_mode = 1'b0;
    hmem_if.req_operation = LOAD;
    hmem_if.req_valid = 1'b0;
    moore_perform_write = 1'b0;

    case (state) inside
        ST_IDLE: begin

        end

        ST_ALLOCATE: begin
            internal_if.miss_recovery_mode = 1'b1;
            hmem_if.req_operation = LOAD;
            hmem_if.req_valid = 1'b1;
            moore_perform_write = 1'b1;
        end

        ST_FLUSH, ST_WRITEBACK: begin
            internal_if.miss_recovery_mode = 1'b1;
            hmem_if.req_operation = STORE;
            hmem_if.req_valid = 1'b1;
        end

        default: begin
            internal_if.miss_recovery_mode = 1'bx;
            hmem_if.req_operation = MO_UNKNOWN;
            hmem_if.req_valid = 1'bx;
            moore_perform_write = 1'bx;
        end
    endcase
end

//// STATE REGISTER ////
always_ff @(posedge clk) begin
    if (rst_if.reset) begin
        state <= ST_IDLE;
        prev_state <= ST_IDLE;
    end else begin
        state <= next_state;
        prev_state <= state;
    end
end

endmodule
