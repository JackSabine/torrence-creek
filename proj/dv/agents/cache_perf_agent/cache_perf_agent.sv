class cache_perf_agent extends uvm_agent;
    `uvm_component_utils(cache_perf_agent)

    uvm_analysis_port #(cache_perf_transaction) perf_ap;

    cache_perf_monitor perf_mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        perf_ap = new(.name("perf_ap"), .parent(this));
        perf_mon = cache_perf_monitor::type_id::create(.name("perf_mon"), .parent(this));
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        perf_mon.perf_ap.connect(perf_ap);
    endfunction
endclass
