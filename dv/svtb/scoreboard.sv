`uvm_analysis_imp_decl( _icache_drv )
`uvm_analysis_imp_decl( _icache_mon )
`uvm_analysis_imp_decl( _dcache_drv )
`uvm_analysis_imp_decl( _dcache_mon )

`uvm_analysis_imp_decl( _icache_perf )
`uvm_analysis_imp_decl( _dcache_perf )
`uvm_analysis_imp_decl( _l2cache_perf )

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_icache_drv #(memory_transaction, scoreboard) aport_icache_drv;
    uvm_analysis_imp_icache_mon #(memory_transaction, scoreboard) aport_icache_mon;
    uvm_analysis_imp_dcache_drv #(memory_transaction, scoreboard) aport_dcache_drv;
    uvm_analysis_imp_dcache_mon #(memory_transaction, scoreboard) aport_dcache_mon;

    uvm_analysis_imp_icache_perf #(cache_perf_transaction, scoreboard) aport_icache_perf;
    uvm_analysis_imp_dcache_perf #(cache_perf_transaction, scoreboard) aport_dcache_perf;
    uvm_analysis_imp_l2cache_perf #(cache_perf_transaction, scoreboard) aport_l2cache_perf;

    uvm_tlm_fifo #(memory_transaction) icache_expected_fifo;
    uvm_tlm_fifo #(memory_transaction) icache_observed_fifo;
    uvm_tlm_fifo #(memory_transaction) dcache_expected_fifo;
    uvm_tlm_fifo #(memory_transaction) dcache_observed_fifo;

    cache_wrapper cache_model;
    cache_config dut_config;
    clock_config clk_config;

    static uint32_t cache_miss_delay;
    static uint32_t cache_flush_delay;

    uint32_t vector_count, pass_count, fail_count;
    uint32_t load_count, store_count, clflush_count;
    uint32_t perf_vector_count, perf_pass_count, perf_fail_count;
    uint32_t icache_count, dcache_count, l2cache_count;

    uvm_tlm_fifo #(cache_perf_transaction) cache_performance_observed_fifos[cache_type_e];

    function void build_phase(uvm_phase phase);
        cache_type_e c;
        string cache_name;

        super.build_phase(phase);

        aport_icache_drv = new("aport_icache_drv", this);
        aport_icache_mon = new("aport_icache_mon", this);
        icache_expected_fifo = new("icache_expected_fifo", this);
        icache_observed_fifo = new("icache_observed_fifo", this);

        aport_dcache_drv = new("aport_dcache_drv", this);
        aport_dcache_mon = new("aport_dcache_mon", this);
        dcache_expected_fifo = new("dcache_expected_fifo", this);
        dcache_observed_fifo = new("dcache_observed_fifo", this);

        cache_model = new(dut_config);

        aport_icache_perf = new("aport_icache_perf", this);
        aport_dcache_perf = new("aport_dcache_perf", this);
        aport_l2cache_perf = new("aport_l2cache_perf", this);

        c = c.first();
        do begin
            if (c != UNASSIGNED) begin
                // Don't try to combine these lines with c.name().tolower() because xelab segfaults over it
                cache_name = c.name();
                cache_name = cache_name.tolower();
                //

                cache_performance_observed_fifos[c] = new({cache_name, "_performance_observed_fifo"}, this);
            end

            c = c.next();
        end while (c != c.first());
    endfunction

    function new (string name, uvm_component parent);
        super.new(name, parent);

        assert(uvm_config_db #(cache_config)::get(
            .cntxt(null),
            .inst_name("*"),
            .field_name("cache_config"),
            .value(dut_config)
        )) else `uvm_fatal(get_full_name(), "Couldn't get cache_config from config db")

        assert(uvm_config_db #(clock_config)::get(
            .cntxt(null),
            .inst_name("*"),
            .field_name("clock_config"),
            .value(clk_config)
        )) else `uvm_fatal(get_full_name(), "Couldn't get clock_config from config db")
    endfunction

    function void predictor(memory_transaction tr, ref uvm_tlm_fifo #(memory_transaction) expected_fifo, input cache_type_e cache_type);
        // tr has t_issued
        // use to predict t_fulfilled

        cache_response_t resp;

        case (tr.req_operation)
            LOAD: begin
                load_count++;
                resp = cache_model.read(tr.req_address, tr.req_size, cache_type);
            end

            STORE: begin
                store_count++;
                resp = cache_model.write(tr.req_address, tr.req_size, tr.req_store_word, cache_type);
            end

            CLFLUSH: begin
                clflush_count++;
            end
        endcase

        case (tr.req_operation) inside
            LOAD, STORE: begin
                tr.req_loaded_word = resp.req_word;
                tr.expect_hit = resp.is_hit;
                if (tr.expect_hit) begin
                    tr.t_fulfilled = tr.t_issued;
                end
            end
        endcase

        tr.t_issued    += clk_config.t_period;
        tr.t_fulfilled += clk_config.t_period;

        `uvm_info("write_drv OUT ", tr.convert2string(), UVM_HIGH)
        void'(expected_fifo.try_put(tr));
    endfunction

    function void observer(memory_transaction tr, ref uvm_tlm_fifo #(memory_transaction) observed_fifo);
        // tr has t_issued and t_fulfilled
        `uvm_info("write_mon OUT ", tr.convert2string(), UVM_HIGH)
        void'(observed_fifo.try_put(tr));
    endfunction

    function void write_icache_drv(memory_transaction tr);
        predictor(tr, icache_expected_fifo, ICACHE);
    endfunction

    function void write_icache_mon(memory_transaction tr);
        observer(tr, icache_observed_fifo);
    endfunction

    function void write_dcache_drv(memory_transaction tr);
        predictor(tr, dcache_expected_fifo, DCACHE);
    endfunction

    function void write_dcache_mon(memory_transaction tr);
        observer(tr, dcache_observed_fifo);
    endfunction

    function void write_to_cache_performance_observed_fifos(cache_perf_transaction tr);
        if (!cache_performance_observed_fifos.exists(tr.origin)) begin
            `uvm_error(get_full_name(), {"write_to_cache_performance_observed_fifos tried to find a fifo with origin ", tr.origin.name(), ", but cache_performance_observed_fifos didn't contain a matching entry"})
            return;
        end

        `uvm_info("write_to_cache_performance_observed_fifos OUT ", tr.convert2string, UVM_HIGH)
        void'(cache_performance_observed_fifos[tr.origin].try_put(tr));
    endfunction

    function void write_icache_perf(cache_perf_transaction tr);
        write_to_cache_performance_observed_fifos(tr);
    endfunction

    function void write_dcache_perf(cache_perf_transaction tr);
        write_to_cache_performance_observed_fifos(tr);
    endfunction

    function void write_l2cache_perf(cache_perf_transaction tr);
        write_to_cache_performance_observed_fifos(tr);
    endfunction

    task comparer(ref uvm_tlm_fifo #(memory_transaction) expected_fifo, ref uvm_tlm_fifo #(memory_transaction) observed_fifo, input cache_type_e cache_type);
        memory_transaction expected_tx, observed_tx;
        bit pass;
        string printout_str;
        string name;

        name = $sformatf("scoreboard comparer<%s>", cache_type.name());

        forever begin
            `uvm_info(name, "WAITING for expected output", UVM_DEBUG)
            expected_fifo.get(expected_tx);
            `uvm_info(name, "WAITING for observed output", UVM_DEBUG)
            observed_fifo.get(observed_tx);

            pass = observed_tx.compare(expected_tx);

            if (expected_tx.expect_hit) pass &= (observed_tx.t_issued == observed_tx.t_fulfilled);
            else                        pass &= (observed_tx.t_issued != observed_tx.t_fulfilled);

            printout_str = $sformatf(
                {
                    "\n",
                    "OBSERVED: %s\n",
                    "EXPECTED: %s\n"
                },
                observed_tx.convert2string(), expected_tx.convert2string()
            );

            if (pass) begin
                vector_pass();
                `uvm_info("PASS: ", printout_str, UVM_HIGH)
            end else begin
                vector_fail();
                `uvm_error("FAIL: ", printout_str)
            end

            assert(expected_tx.origin == cache_type)
                else `uvm_error(name, $sformatf("Received driven transaction from incorrect origin (%s)", expected_tx.origin.name()))

            case(cache_type)
                ICACHE: icache_count++;
                DCACHE: dcache_count++;
                L2CACHE: l2cache_count++;
            endcase
        end
    endtask

    uint32_t num_performance_comparisons;

    task performance_comparer(input cache_type_e cache_type);
        cache_perf_transaction observed_tx, expected_tx;
        bit pass;
        string printout_str;
        string name;

        num_performance_comparisons++;

        if (!cache_performance_observed_fifos.exists(cache_type)) begin
            `uvm_error(get_full_name(), {"performance_comparer tried to find a fifo with cache_type ", cache_type.name(), ", but cache_performance_observed_fifos didn't contain a matching entry"})
            return;
        end

        name = $sformatf("scoreboard performance_comparer<%s>", cache_type.name());

        forever begin
            pass = 1'b1;

            `uvm_info(name, "WAITING for observed performance output", UVM_DEBUG)
            cache_performance_observed_fifos[cache_type].get(observed_tx);
            expected_tx = cache_model.get_stats(cache_type);

            pass &= observed_tx.compare(expected_tx);
            pass &= observed_tx.origin == cache_type;

            printout_str = $sformatf(
                {
                    "\n",
                    "*** OBSERVED ***\n%s\n",
                    "*** EXPECTED ***\n%s\n"
                },
                observed_tx.convert2string(), expected_tx.convert2string()
            );

            if (pass) begin
                performance_pass();
                `uvm_info("PERF PASS: ", printout_str, UVM_HIGH)
            end else begin
                performance_fail();
                `uvm_error("PERF FAIL: ", printout_str)
            end

            assert (observed_tx.origin == cache_type)
                else `uvm_error(name, $sformatf("Received performance transaction from incorrect origin (%s)", observed_tx.origin.name()))
        end
    endtask

    function void performance_comparer_main_memory();
        cache_perf_transaction observed_tx, expected_tx;
        bit pass;
        main_memory dut_memory_model;
        string printout_str;

        num_performance_comparisons++;

        assert(uvm_config_db #(main_memory)::get(
            .cntxt(this),
            .inst_name(""),
            .field_name("dut_memory_model"),
            .value(dut_memory_model)
        )) else `uvm_error(get_full_name(), "Couldn't get dut_memory_model in performance_comparer_main_memory")

        observed_tx = dut_memory_model.get_stats();
        expected_tx = cache_model.get_main_memory_stats();

        pass = observed_tx.compare(expected_tx);

        printout_str = $sformatf(
            {
                "\n",
                "*** OBSERVED ***\n%s\n",
                "*** EXPECTED ***\n%s\n"
            },
            observed_tx.convert2string(), expected_tx.convert2string()
        );

        if (pass) begin
            performance_pass();
            `uvm_info("MAIN MEMORY PERF PASS: ", printout_str, UVM_HIGH)
        end else begin
            performance_fail();
            `uvm_error("MAIN MEMORY PERF FAIL: ", printout_str)
        end
    endfunction

    task run_phase(uvm_phase phase);
        fork
            comparer(icache_expected_fifo, icache_observed_fifo, ICACHE);
            comparer(dcache_expected_fifo, dcache_observed_fifo, DCACHE);
            performance_comparer(ICACHE);
            performance_comparer(DCACHE);
            performance_comparer(L2CACHE);
        join
    endtask

    function void extract_phase(uvm_phase phase);
        performance_comparer_main_memory();
    endfunction

    bit test_passed;

    function void check_phase(uvm_phase phase);
        uvm_report_server server;
        cache_perf_transaction observed_tx;

        super.check_phase(phase);

        test_passed = 1'b1;

        // Performance vector checks
        test_passed &= (perf_vector_count == num_performance_comparisons) && (perf_fail_count == 0);

        // Runtime vector checks
        test_passed &= (vector_count != 0) && (fail_count == 0);

        // UVM Report Server Checks
        server = uvm_report_server::get_server();
        test_passed &= (server.get_severity_count(UVM_ERROR) == 0);
    endfunction

    function void report_phase(uvm_phase phase);
        string report_str;
        string pass_fail_str;

        super.report_phase(phase);

        report_str = "";

        report_str = {
            report_str,
            $sformatf(
                {
                    "\n",
                    "--------------\n",
                    "--- TOTALS ---\n",
                    "--------------\n",
                    "\n",
                    "* load_count:    %0d\n",
                    "* store_count:   %0d\n",
                    "* clflush_count: %0d\n",
                    "* icache transactions: %0d\n",
                    "* dcache transactions: %0d\n"
                },
                load_count,
                store_count,
                clflush_count,
                icache_count,
                dcache_count
            )
        };

        report_str = {
            report_str,
            "\n",
            "-------------------------------------------\n",
            "--- EXPECTED CACHE PERFORMANCE COUNTERS ---\n",
            "-------------------------------------------\n",
            "\n",
            cache_model.get_stats(ICACHE).convert2string(),
            "\n",
            cache_model.get_stats(DCACHE).convert2string(),
            "\n",
            cache_model.get_stats(L2CACHE).convert2string(),
            "\n",
            "(UNASSIGNED === main memory)\n",
            cache_model.get_main_memory_stats().convert2string()
        };

        report_str = {
            $sformatf("* Runtime vectors: %0d ran, %0d passed, %0d failed\n", vector_count, pass_count, fail_count),
            $sformatf("* Performance vectors: %0d compared (%0d expected), %0d passed, %0d failed\n", perf_vector_count, num_performance_comparisons, perf_pass_count, perf_fail_count),
            report_str
        };

        if (test_passed) begin
            pass_fail_str = {
                "\n\n",
                "---------------------------------------------------\n",
                "-                   TEST PASSED                   -\n",
                "---------------------------------------------------\n",
                "\n"
            };

            report_str = {
                report_str,
                pass_fail_str
            };

            `uvm_info("PASSED", report_str, UVM_LOW)
        end else begin
            pass_fail_str = {
                "\n\n",
                "---------------------------------------------------\n",
                "-                   TEST FAILED                   -\n",
                "---------------------------------------------------\n",
                "\n"
            };

            report_str = {
                report_str,
                pass_fail_str
            };

            `uvm_error("FAILED", report_str)
        end
    endfunction

    function void vector_pass();
        vector_count++;
        pass_count++;
    endfunction

    function void vector_fail();
        vector_count++;
        fail_count++;
    endfunction

    function void performance_pass();
        perf_vector_count++;
        perf_pass_count++;
    endfunction

    function void performance_fail();
        perf_vector_count++;
        perf_fail_count++;
    endfunction

endclass