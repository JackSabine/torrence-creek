class l1_basic_test extends cache_base_test;
    `uvm_component_utils(l1_basic_test)

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

    virtual task main_phase(uvm_phase phase);
        icache_random_access_seq icache_seq;
        dcache_random_access_seq dcache_seq;
        base_memory_response_seq mem_rsp_seq;

        phase.raise_objection(this);

        mem_rsp_seq = base_memory_response_seq::type_id::create(.name("mem_rsp_seq"));

        // sequences appear to gain context when started on some sequencer, but we provide it here just in case
        icache_seq = icache_random_access_seq::type_id::create(.name("icache_seq"), .contxt(mem_env.icache_creq_agent.creq_seqr.get_full_name()));
        assert(icache_seq.randomize()) else `uvm_fatal(get_full_name(), "Couldn't randomize icache_seq")
        icache_seq.print();

        dcache_seq = dcache_random_access_seq::type_id::create(.name("dcache_seq"), .contxt(mem_env.dcache_creq_agent.creq_seqr.get_full_name()));
        assert(dcache_seq.randomize()) else `uvm_fatal(get_full_name(), "Couldn't randomize dcache_seq")
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