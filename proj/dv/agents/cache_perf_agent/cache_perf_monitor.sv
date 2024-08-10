class cache_perf_monitor extends uvm_monitor;
    `uvm_component_utils(cache_perf_monitor)

    uvm_analysis_port #(cache_perf_transaction) perf_ap;

    virtual cache_performance_if perf_vi;

    l1_type_e cache_type;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        assert(uvm_config_db #(virtual cache_performance_if)::get(
            .cntxt(this),
            .inst_name(""),
            .field_name("cache_perf_if"),
            .value(perf_vi)
        )) else `uvm_fatal(get_full_name(), "Couldn't get cache_perf_if from config db")

        assert(uvm_config_db #(l1_type_e)::get(
            .cntxt(this),
            .inst_name(""),
            .field_name("l1_type"),
            .value(cache_type)
        )) else `uvm_fatal(get_full_name(), "Couldn't get l1_type from config db")

        perf_ap = new(.name("perf_ap"), .parent(this));
    endfunction

    task post_shutdown_phase(uvm_phase phase);
        cache_perf_transaction perf_tx;

        super.post_shutdown_phase(phase);

        perf_tx = cache_perf_transaction::type_id::create(.name("perf_tx"));

        perf_tx.hits = perf_vi.hit_value;
        perf_tx.misses = perf_vi.miss_value;
        perf_tx.reads = perf_vi.read_value;
        perf_tx.writes = perf_vi.write_value;

        perf_tx.origin = this.cache_type;

        perf_ap.write(perf_tx);
    endtask
endclass
