module tb_top;
    import uvm_pkg::*;
    import torrence_pkg::*;

    parameter LINE_SIZE = 32;
    parameter CACHE_SIZE = 1024;
    parameter XLEN = 32;

    cache_config dut_config;
    clock_config clk_config;

    bit clk_enabled = 1'b0;
    logic clk = 1'b0;
    cache_if         icache_req_if(clk);
    higher_memory_if icache_rsp_if(clk);
    cache_if         dcache_req_if(clk);
    higher_memory_if dcache_rsp_if(clk);
    reset_if rst_if(clk);

    icache #(
        .LINE_SIZE(LINE_SIZE),
        .CACHE_SIZE(CACHE_SIZE),
        .XLEN(XLEN)
    ) icache_dut (
        .clk(clk),
        .rst_if(rst_if),
        .req_if(icache_req_if),
        .hmem_if(icache_rsp_if)
    );

    dcache #(
        .LINE_SIZE(LINE_SIZE),
        .CACHE_SIZE(CACHE_SIZE),
        .XLEN(XLEN)
    ) dcache_dut (
        .clk(clk),
        .rst_if(rst_if),
        .req_if(dcache_req_if),
        .hmem_if(dcache_rsp_if)
    );

    initial begin
        @(posedge clk_enabled);

        forever begin
            #(clk_config.t_half_period);
            clk = ~clk;
        end
    end

    initial begin
        dut_config = cache_config::type_id::create("dut_config");
        dut_config.set(LINE_SIZE, CACHE_SIZE, 1);
        dut_config.print();

        clk_config = clock_config::type_id::create("clk_config");
        assert(clk_config.randomize() with { t_period == 2; })
            else `uvm_fatal("tb_top", "Could not randomize clk_config")
        `uvm_info("tb_top", clk_config.sprint(), UVM_LOW)
        clk_enabled = 1'b1;

        uvm_config_db #(virtual cache_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.icache_creq_agent.*"),
            .field_name("memory_requester_if"),
            .value(icache_req_if)
        );
        uvm_config_db #(virtual higher_memory_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.icache_mrsp_agent.*"),
            .field_name("memory_responder_if"),
            .value(icache_rsp_if)
        );
        uvm_config_db #(virtual cache_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.dcache_creq_agent.*"),
            .field_name("memory_requester_if"),
            .value(dcache_req_if)
        );
        uvm_config_db #(virtual higher_memory_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.mem_env.dcache_mrsp_agent.*"),
            .field_name("memory_responder_if"),
            .value(dcache_rsp_if)
        );
        uvm_config_db #(virtual reset_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.*"),
            .field_name("reset_if"),
            .value(rst_if)
        );
        uvm_config_db #(cache_config)::set(
            .cntxt(null),
            .inst_name("*"),
            .field_name("cache_config"),
            .value(dut_config)
        );
        uvm_config_db #(clock_config)::set(
            .cntxt(null),
            .inst_name("*"),
            .field_name("clock_config"),
            .value(clk_config)
        );
        run_test();
    end
endmodule