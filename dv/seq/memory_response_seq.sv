class memory_response_seq extends uvm_sequence #(memory_transaction);
    `uvm_object_utils(memory_response_seq)

    memory_rsp_sequencer p_sequencer;
    memory_transaction mem_tx;

    main_memory dut_memory_model;

    function new (string name = "");
        super.new(name);
        assert(uvm_config_db #(main_memory)::get(
            .cntxt(null), // `this` inside a sequence doesn't work since all seq start on null_sequencer
            .inst_name(""),
            .field_name("dut_memory_model"),
            .value(dut_memory_model)
        )) else `uvm_fatal(get_full_name(), "Couldn't get dut_memory_model from config db")
    endfunction

    virtual task seed_memory(uint32_t defaults [uint32_t]);
        uint32_t addr;
        foreach (defaults[addr]) begin
            dut_memory_model.tb_write(addr, defaults[addr]);
        end
    endtask

    virtual task body();
        $cast(p_sequencer, m_sequencer);
        `uvm_info(get_type_name(), $sformatf("%s is starting", get_sequence_path()), UVM_MEDIUM)

        forever begin
            // Get from the analysis port
            p_sequencer.mem_tx_fifo.get(mem_tx);

            case (mem_tx.req_operation)
            STORE: mem_tx.req_loaded_word = dut_memory_model.write(mem_tx.req_address, mem_tx.req_size, mem_tx.req_store_word).req_word;
            LOAD:  mem_tx.req_loaded_word = dut_memory_model.read(mem_tx.req_address, mem_tx.req_size).req_word;
            default: continue;
            endcase

            `uvm_do_with(
                req, {
                    req.req_address     == mem_tx.req_address;
                    req.req_operation   == mem_tx.req_operation;
                    req.req_size        == mem_tx.req_size;
                    req.req_loaded_word == mem_tx.req_loaded_word;
                }
            )
        end
    endtask
endclass
