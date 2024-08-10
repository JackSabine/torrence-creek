module tb_top;
    import uvm_pkg::*;
    import torrence_pkg::*;
    import torrence_types::*;

    parameter LINE_SIZE = 32;
    parameter ICACHE_SIZE = 1024;
    parameter ICACHE_ASSOC = 1;
    parameter DCACHE_SIZE = 1024;
    parameter DCACHE_ASSOC = 1;
    parameter L2_SIZE = 4096;
    parameter L2_ASSOC = 4;
    parameter XLEN = 32;

    cache_config dut_config;
    clock_config clk_config;

    bit clk_enabled = 1'b0;
    logic clk = 1'b0;
    memory_if icache_req_if(clk);
    memory_if dcache_req_if(clk);
    memory_if hmem_if(clk);
    reset_if rst_if(clk);

    cache_performance_if icache_perf_if(clk);
    cache_performance_if dcache_perf_if(clk);
    cache_performance_if l2_perf_if(clk);

    memory_system #(
        .XLEN(XLEN),
        .LINE_SIZE(LINE_SIZE),

        .ICACHE_SIZE(ICACHE_SIZE),
        .ICACHE_ASSOC(ICACHE_ASSOC),

        .DCACHE_SIZE(DCACHE_SIZE),
        .DCACHE_ASSOC(DCACHE_ASSOC),

        .L2_SIZE(L2_SIZE),
        .L2_ASSOC(L2_ASSOC)
    ) dut (
        .clk(clk),
        .rst_if(rst_if),
        .icache_req_if(icache_req_if),
        .dcache_req_if(dcache_req_if),
        .hmem_if(hmem_if),
        .icache_perf_if(icache_perf_if),
        .dcache_perf_if(dcache_perf_if),
        .l2_perf_if(l2_perf_if)
    );

    initial begin
        @(posedge clk_enabled);

        forever begin
            #(clk_config.t_half_period);
            clk = ~clk;
        end
    end

    initial begin
        // Instruction Cache request interface
        uvm_config_db #(virtual memory_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.icache_creq_agent.*"),
            .field_name("memory_requester_if"),
            .value(icache_req_if)
        );

        // Instruction Cache performance counter interface
        uvm_config_db #(virtual cache_performance_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.icache_perf_agent.*"),
            .field_name("cache_perf_if"),
            .value(icache_perf_if)
        );

        uvm_config_db #(l1_type_e)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.icache_perf_agent.*"),
            .field_name("l1_type"),
            .value(ICACHE)
        );

        // Data Cache request interface
        uvm_config_db #(virtual memory_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.dcache_creq_agent.*"),
            .field_name("memory_requester_if"),
            .value(dcache_req_if)
        );

        // Data Cache performance counter interface
        uvm_config_db #(virtual cache_performance_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.dcache_perf_agent.*"),
            .field_name("cache_perf_if"),
            .value(dcache_perf_if)
        );

        uvm_config_db #(l1_type_e)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.dcache_perf_agent.*"),
            .field_name("l1_type"),
            .value(DCACHE)
        );

        // L2 Cache performance counter interface
        uvm_config_db #(virtual cache_performance_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.l2_perf_agent.*"),
            .field_name("cache_perf_if"),
            .value(l2_perf_if)
        );

        // Higher Memory response interface
        uvm_config_db #(virtual memory_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.mem_rsp_agent.*"),
            .field_name("memory_responder_if"),
            .value(hmem_if)
        );

        // Reset interface
        uvm_config_db #(virtual reset_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.*"),
            .field_name("reset_if"),
            .value(rst_if)
        );

        // DUT configuration
        dut_config = cache_config::type_id::create("dut_config");
        dut_config.set(
            LINE_SIZE,
            ICACHE_SIZE,
            ICACHE_ASSOC,
            DCACHE_SIZE,
            DCACHE_ASSOC,
            L2_SIZE,
            L2_ASSOC
        );
        dut_config.print();

        uvm_config_db #(cache_config)::set(
            .cntxt(null),
            .inst_name("*"),
            .field_name("cache_config"),
            .value(dut_config)
        );

        // Clock configuration
        clk_config = clock_config::type_id::create("clk_config");
        assert(clk_config.randomize() with { t_period == 2; })
            else `uvm_fatal("tb_top", "Could not randomize clk_config")
        `uvm_info("tb_top", clk_config.sprint(), UVM_LOW)
        clk_enabled = 1'b1;

        uvm_config_db #(clock_config)::set(
            .cntxt(null),
            .inst_name("*"),
            .field_name("clock_config"),
            .value(clk_config)
        );

        // UVM test run
        run_test();
    end
endmodule