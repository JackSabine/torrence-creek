interface cache_internal_if;
    logic miss_recovery_mode;
    logic clear_selected_dirty_bit;
    logic set_selected_dirty_bit;
    logic perform_write;
    logic clear_selected_valid_bit;
    logic finish_new_line_install;
    logic set_hmem_block_address;
    logic use_victim_tag_for_hmem_block_address;
    logic reset_counter;
    logic decrement_counter;

    logic counter_done;
    logic valid_block_match;
    logic valid_dirty_bit;

    modport datapath (
        input
            miss_recovery_mode,
            clear_selected_dirty_bit,
            set_selected_dirty_bit,
            perform_write,
            clear_selected_valid_bit,
            finish_new_line_install,
            set_hmem_block_address,
            use_victim_tag_for_hmem_block_address,
            reset_counter,
            decrement_counter,

        output
            counter_done,
            valid_block_match,
            valid_dirty_bit
    );

    modport controller (
        output
            miss_recovery_mode,
            clear_selected_dirty_bit,
            set_selected_dirty_bit,
            perform_write,
            clear_selected_valid_bit,
            finish_new_line_install,
            set_hmem_block_address,
            use_victim_tag_for_hmem_block_address,
            reset_counter,
            decrement_counter,

        input
            counter_done,
            valid_block_match,
            valid_dirty_bit
    );
endinterface