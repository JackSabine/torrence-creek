class environment extends uvm_env;
    `uvm_component_utils(environment)

    cache_req_agent  icache_creq_agent;
    cache_req_agent  dcache_creq_agent;
    cache_perf_agent icache_perf_agent;
    cache_perf_agent dcache_perf_agent;
    cache_perf_agent l2cache_perf_agent;
    memory_rsp_agent mem_rsp_agent;
    reset_agent rst_agent;
    scoreboard sb;

    main_memory dut_memory_model;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        dut_memory_model = new("dut_memory_model");
        uvm_config_db #(main_memory)::set(
            .cntxt(null),
            .inst_name("*"),
            .field_name("dut_memory_model"),
            .value(dut_memory_model)
        );

        icache_creq_agent  = cache_req_agent::type_id::create(.name("icache_creq_agent"), .parent(this));
        dcache_creq_agent  = cache_req_agent::type_id::create(.name("dcache_creq_agent"), .parent(this));
        icache_perf_agent  = cache_perf_agent::type_id::create(.name("icache_perf_agent"), .parent(this));
        dcache_perf_agent  = cache_perf_agent::type_id::create(.name("dcache_perf_agent"), .parent(this));
        l2cache_perf_agent = cache_perf_agent::type_id::create(.name("l2cache_perf_agent"), .parent(this));
        mem_rsp_agent = memory_rsp_agent::type_id::create(.name("mem_rsp_agent"), .parent(this));
        rst_agent  = reset_agent::type_id::create(.name("rst_agent"), .parent(this));
        sb         = scoreboard::type_id::create(.name("sb"), .parent(this));
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        icache_creq_agent.creq_mon_ap.connect(sb.aport_icache_mon);
        icache_creq_agent.creq_drv_ap.connect(sb.aport_icache_drv);

        dcache_creq_agent.creq_mon_ap.connect(sb.aport_dcache_mon);
        dcache_creq_agent.creq_drv_ap.connect(sb.aport_dcache_drv);

        icache_perf_agent.perf_ap.connect(sb.aport_icache_perf);
        dcache_perf_agent.perf_ap.connect(sb.aport_dcache_perf);
        l2cache_perf_agent.perf_ap.connect(sb.aport_l2cache_perf);
    endfunction
endclass