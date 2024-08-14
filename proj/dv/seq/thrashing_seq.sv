class thrashing_seq extends base_access_seq;
    rand uint32_t num_batches_to_access;
    rand uint32_t num_accesses_per_block;
    rand uint32_t num_blocks_per_batch;
    rand uint32_t num_repetitions_per_batch;

    randomizable_2d_array #(uint32_t) block_array;

    `uvm_object_utils_begin(thrashing_seq)
        `uvm_field_int(num_batches_to_access,     UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(num_accesses_per_block,    UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(num_blocks_per_batch,      UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(num_repetitions_per_batch, UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end

    constraint blocks_con {
        num_batches_to_access == 16;
        num_accesses_per_block == 4;
        soft num_blocks_per_batch == 4;
        num_repetitions_per_batch == 2;
    }

    function new(string name = "");
        super.new(name);
        block_array = new("block_array");
    endfunction

    function void post_randomize();
        uint32_t set;
        uint32_t block_array_size;
        uint32_t tmp;

        block_array_size = num_batches_to_access * num_blocks_per_batch;

        `uvm_info(
            get_full_name(),
            $sformatf(
                "num_batches_to_access = %0d, num_blocks_per_batch = %0d, block_array_size = %0d",
                num_batches_to_access,
                num_blocks_per_batch,
                block_array_size
            ),
            UVM_MEDIUM
        )

        assert(block_array.randomize() with {
            array_size == block_array_size;
            num_rows == num_batches_to_access;
            num_cols == num_blocks_per_batch;
        }) else `uvm_fatal(get_full_name(), "Couldn't randomize block_array")

        for (uint32_t row = 0; row < num_batches_to_access; row++) begin
            for (uint32_t col = 0; col < num_blocks_per_batch; col++) begin
                case (cache_type)
                    ICACHE: block_array.set(row, col, block_array.at(row, col) & ~`RO_RW_MEMORY_BOUNDARY);
                    DCACHE: block_array.set(row, col, block_array.at(row, col) |  `RO_RW_MEMORY_BOUNDARY);
                endcase

                // Base the 1:(num_blocks_per_batch - 1) set bits on the 0th
                if (col == 0) begin
                    set = block_array.at(row, col) & set_mask;
                end else begin
                    tmp = block_array.at(row, col);
                    tmp &= ~set_mask;
                    tmp |= set;

                    block_array.set(row, col, tmp);
                end
            end
        end

        `uvm_info(get_full_name(), block_array.convert2string(), UVM_MEDIUM)
    endfunction

    task body();
        uint32_t block;
        uint32_t batch;

        `uvm_info(get_type_name(), $sformatf("%s is starting", get_name()), UVM_MEDIUM)

        repeat (num_batches_to_access) begin
            // Pick an index
            assert(std::randomize(batch) with { batch < block_array.get_num_rows(); })
                else `uvm_fatal(get_full_name(), "Couldn't randomize batch")

            repeat (num_repetitions_per_batch) begin
                for (uint32_t i = 0; i < num_blocks_per_batch; i++) begin
                    block = block_array.at(batch, i);
                end

                repeat(num_accesses_per_block) begin
                    // Must create with a context in case of instance overriding
                    req = memory_transaction::type_id::create(.name("req"), .contxt(get_full_name()));
                    start_item(req);
                    assert(req.randomize() with { req_address inside {[block : block+offset_mask]}; })
                        else `uvm_fatal(get_full_name(), "Couldn't randomize req")
                    finish_item(req);
                end
            end
        end
    endtask
endclass



class icache_thrashing_seq extends thrashing_seq;
    `uvm_object_utils(icache_thrashing_seq)

    function new(string name = "");
        super.new(name);
        cache_type = ICACHE;
    endfunction
endclass



class dcache_thrashing_seq extends thrashing_seq;
    `uvm_object_utils(dcache_thrashing_seq)

    function new(string name = "");
        super.new(name);
        cache_type = DCACHE;
    endfunction
endclass
