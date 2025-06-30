class l1_thrashing_test extends cache_base_test;
    `uvm_component_utils(l1_thrashing_test)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void set_transaction_type();
        `uvm_info(get_name(), "Overriding types", UVM_LOW)

        `print_uvm_factory()

        // memory_transaction type is overriden when created in any component/sequence under the following agents
        memory_transaction::type_id::set_inst_override(icache_transaction::get_type(), {mem_env.icache_creq_agent.get_full_name(), ".*"});
        memory_transaction::type_id::set_inst_override(dcache_transaction::get_type(), {mem_env.dcache_creq_agent.get_full_name(), ".*"});

        `print_uvm_factory(0)
    endfunction

    function uint32_t get_cache_assoc(input cache_type_e cache_type);
        cache_config cfg;

        assert(uvm_config_db #(cache_config)::get(
            .cntxt(this),
            .inst_name(""),
            .field_name("cache_config"),
            .value(cfg)
        )) else `uvm_fatal(get_full_name(), "Unable to get cache_config from config db")

        case (cache_type)
            ICACHE: return cfg.icache_assoc;
            DCACHE: return cfg.dcache_assoc;
            L2CACHE: return cfg.l2_assoc;
            default: return 0;
        endcase
    endfunction

    virtual task main_phase(uvm_phase phase);
        icache_thrashing_seq icache_seq;
        dcache_thrashing_seq dcache_seq;
        base_memory_response_seq mem_rsp_seq;

        phase.raise_objection(this);

        mem_rsp_seq = base_memory_response_seq::type_id::create(.name("mem_rsp_seq"));

        // sequences appear to gain context when started on some sequencer, but we provide it here just in case
        icache_seq = icache_thrashing_seq::type_id::create(.name("icache_seq"), .contxt(mem_env.icache_creq_agent.creq_seqr.get_full_name()));
        assert(icache_seq.randomize() with { num_blocks_per_batch == get_cache_assoc(ICACHE) + 1; })
            else `uvm_fatal(get_full_name(), "Couldn't randomize icache_seq")
        icache_seq.print();

        dcache_seq = dcache_thrashing_seq::type_id::create(.name("dcache_seq"), .contxt(mem_env.dcache_creq_agent.creq_seqr.get_full_name()));
        assert(dcache_seq.randomize() with { num_blocks_per_batch == get_cache_assoc(DCACHE) + 1; })
            else `uvm_fatal(get_full_name(), "Couldn't randomize dcache_seq")
        dcache_seq.print();

        fork
            fork // Both must complete
                icache_seq.start(mem_env.icache_creq_agent.creq_seqr);
                dcache_seq.start(mem_env.dcache_creq_agent.creq_seqr);
            join
            mem_rsp_seq.start(mem_env.mem_rsp_agent.mrsp_seqr); // Runs forever
        join_any

        phase.drop_objection(this);
    endtask
endclass