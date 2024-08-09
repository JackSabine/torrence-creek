class base_access_seq extends uvm_sequence #(memory_transaction);
    `uvm_object_utils(base_access_seq)

    rand l1_type_e cache_type;

    uint32_t block_mask;
    uint32_t offset_mask;
    uint32_t set_mask;

    constraint cache_type_con {
        soft cache_type == UNASSIGNED;
    }

    function new(string name = "");
        super.new(name);
    endfunction

    local function void generate_masks();
        uint32_t mask;
        cache_config cfg;

        assert(uvm_config_db #(cache_config)::get(
            .cntxt(null),
            .inst_name("*"),
            .field_name("cache_config"),
            .value(cfg)
        )) else `uvm_fatal(get_full_name(), "Couldn't get cache_config from config db")

        cfg.generate_block_mask_and_offset_mask(cache_type, block_mask, offset_mask);
        cfg.generate_set_mask(cache_type, set_mask);
    endfunction

    function void post_randomize();
        generate_masks();
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("%s is starting", get_name()), UVM_MEDIUM)
    endtask
endclass
