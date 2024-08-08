class random_access_seq extends base_access_seq;
    rand uint32_t num_blocks_to_access;
    rand uint32_t accesses_per_block;

    rand uint32_t block_array[];

    cache_config dut_config;

    `uvm_object_utils_begin(random_access_seq)
        `uvm_field_int(num_blocks_to_access, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(accesses_per_block,   UVM_ALL_ON | UVM_DEC)
        `uvm_field_array_int(block_array,    UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(block_mask,           UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(offset_mask,          UVM_ALL_ON | UVM_HEX)
    `uvm_object_utils_end

    constraint blocks_con {
        soft num_blocks_to_access inside {[20:40]};
        accesses_per_block == 8;

        block_array.size() == num_blocks_to_access;
        // unique {block_array}; -- unsupported in Vivado 2022.2
    }

    function new(string name = "");
        super.new(name);
    endfunction

    function void post_randomize();
        super.post_randomize();

        foreach (block_array[i]) begin
            block_array[i] &= block_mask;

            case (cache_type)
            ICACHE: block_array[i] &= ~`RO_RW_MEMORY_BOUNDARY;
            DCACHE: block_array[i] |=  `RO_RW_MEMORY_BOUNDARY;
            endcase
        end
    endfunction

    task body();
        uint32_t block;

        `uvm_info(get_type_name(), $sformatf("%s is starting", get_name()), UVM_MEDIUM)

        repeat (num_blocks_to_access) begin
            assert(std::randomize(block) with { block inside {block_array}; }) else `uvm_fatal(get_full_name(), "Couldn't randomize block")

            repeat(accesses_per_block) begin
                // Must create with a context in case of instance overriding
                req = memory_transaction::type_id::create(.name("req"), .contxt(get_full_name()));
                start_item(req);
                assert(req.randomize() with { req_address inside {[block : block+offset_mask]}; }) else `uvm_fatal(get_full_name(), "Couldn't randomize req")
                finish_item(req);
            end
        end
    endtask
endclass



class icache_random_access_seq extends random_access_seq;
    `uvm_object_utils(icache_random_access_seq)

    constraint cache_type_con {
        cache_type == ICACHE;
    }

    function new(string name = "");
        super.new(name);
    endfunction
endclass



class dcache_random_access_seq extends random_access_seq;
    `uvm_object_utils(dcache_random_access_seq)

    constraint cache_type_con {
        cache_type == DCACHE;
    }

    function new(string name = "");
        super.new(name);
    endfunction
endclass
