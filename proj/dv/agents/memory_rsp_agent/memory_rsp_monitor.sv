class memory_rsp_monitor extends uvm_monitor;
    `uvm_component_utils(memory_rsp_monitor)

    uvm_analysis_port #(memory_transaction) mrsp_ap;

    virtual memory_if rsp_vi;

    main_memory dut_memory_model;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        assert(uvm_config_db #(virtual memory_if)::get(
            .cntxt(this),
            .inst_name(""),
            .field_name("memory_responder_if"),
            .value(rsp_vi)
        )) else `uvm_fatal(get_full_name(), "Couldn't get memory_responder_if from config db")
        assert(uvm_config_db #(main_memory)::get(
            .cntxt(this),
            .inst_name(""),
            .field_name("dut_memory_model"),
            .value(dut_memory_model)
        )) else `uvm_fatal(get_full_name(), "Couldn't get dut_memory_model from config db")
        mrsp_ap = new(.name("mrsp_ap"), .parent(this));
    endfunction

    task run_phase(uvm_phase phase);
        memory_transaction mem_tx;
        memory_transaction prev_mem_tx;

        bit first_tx;

        first_tx = 1'b1;

        forever begin
            @(negedge rsp_vi.clk);

            if (rsp_vi.req_valid) begin
                mem_tx = memory_transaction::type_id::create(.name("mem_tx"), .contxt(get_full_name()));

                mem_tx.req_address    = rsp_vi.req_address;
                mem_tx.req_operation  = memory_operation_e'(rsp_vi.req_operation);
                mem_tx.req_size       = WORD;
                mem_tx.req_store_word = rsp_vi.req_store_word;

                if (!first_tx) begin
                    // Skip cases where the previous transaction is the same
                    // If there is a delay in fulfilling the req, we don't want to
                    // query the dut's memory model and trigger any statistics counters
                    if (mem_tx.compare_req_inputs(prev_mem_tx)) begin
                        `uvm_info(get_full_name(), "Previous tx was same as current tx, skipping it", UVM_DEBUG)
                        continue;
                    end
                end

                if (mem_tx.req_operation == STORE) begin
                    void'(dut_memory_model.write(mem_tx.req_address, WORD, mem_tx.req_store_word));
                end else if (mem_tx.req_operation == LOAD) begin
                    mem_tx.req_loaded_word = dut_memory_model.read(mem_tx.req_address, WORD).req_word;
                end

                mem_tx.t_issued = $time();

                `uvm_info(
                    get_full_name(),
                    $sformatf("Received request from cache:\n%s", mem_tx.convert2string()),
                    UVM_DEBUG
                )
                mrsp_ap.write(mem_tx);

                first_tx = 1'b0;
                prev_mem_tx = mem_tx;
            end
        end
   endtask

endclass
