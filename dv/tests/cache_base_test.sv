class cache_base_test extends uvm_test;
    `uvm_component_utils(cache_base_test)

    environment mem_env;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_root::get().set_timeout(100000ns, 1);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mem_env = environment::type_id::create(.name("mem_env"), .parent(this));
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        set_transaction_type();
    endfunction

    virtual function void set_transaction_type();

    endfunction

    virtual function cache_type_e choose_active_agent();
        return UNASSIGNED;
    endfunction

    task reset_phase(uvm_phase phase);
        reset_seq rst_seq;

        phase.raise_objection(this);

        rst_seq = reset_seq::type_id::create(.name("rst_seq"));
        assert(rst_seq.randomize()) else `uvm_fatal(get_full_name(), "Couldn't randomize rst_seq");
        rst_seq.print();
        rst_seq.start(mem_env.rst_agent.rst_seqr);

        phase.drop_objection(this);
    endtask

    virtual task main_phase(uvm_phase phase);
        random_access_seq mem_seq;
        base_memory_response_seq mem_rsp_seq;
        cache_type_e target;

        phase.raise_objection(this);

        mem_rsp_seq = base_memory_response_seq::type_id::create(.name("mem_rsp_seq"));

        mem_seq = random_access_seq::type_id::create(.name("mem_seq"));
        assert(mem_seq.randomize()) else `uvm_fatal(get_full_name(), "Couldn't randomize mem_seq")
        mem_seq.print();

        target = choose_active_agent();

        fork
            begin // Runs until complete
                case (target)
                ICACHE: mem_seq.start(mem_env.icache_creq_agent.creq_seqr);
                DCACHE: mem_seq.start(mem_env.dcache_creq_agent.creq_seqr);
                default: `uvm_fatal(get_full_name(), $sformatf("unimplemented target %s", target.name()))
                endcase
            end
            mem_rsp_seq.start(mem_env.mem_rsp_agent.mrsp_seqr); // Runs forever
        join_any

        phase.drop_objection(this);
    endtask
endclass
