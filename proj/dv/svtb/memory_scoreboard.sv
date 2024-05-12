`uvm_analysis_imp_decl( _drv )
`uvm_analysis_imp_decl( _mon )

class memory_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(memory_scoreboard)

    uvm_analysis_imp_drv #(memory_transaction, memory_scoreboard) aport_drv;
    uvm_analysis_imp_mon #(memory_transaction, memory_scoreboard) aport_mon;

    uvm_tlm_fifo #(memory_transaction) expfifo;
    uvm_tlm_fifo #(memory_transaction) outfifo;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        aport_drv = new("aport_drv", this);
        aport_mon = new("aport_mon", this);
    endfunction

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write_drv(memory_transaction tr);

    endfunction

    function void write_mon(memory_transaction tr);
        `uvm_info("write_mon OUT ", tr.convert2string(), UVM_HIGH)
        void'(outfifo.try_put(tr));
    endfunction

    task run_phase(uvm_phase phase);
        memory_transaction exp_tr, out_tr;
        forever begin
            `uvm_info("scoreboard run task", "WAITING for expected output", UVM_DEBUG)
            expfifo.get(exp_tr);
            `uvm_info("scoreboard run task", "WAITING for actual output", UVM_DEBUG)
            outfifo.get(out_tr);
            if (out_tr.compare(exp_tr)) begin
                PASS();
                `uvm_info ("PASS ", $sformatf("Actual=%s Expected=%s \n", out_tr.convert2string(), exp_tr.convert2string()), UVM_HIGH)
            end else begin
                ERROR();
                `uvm_error("ERROR", $sformatf("Actual=%s Expected=%s \n",
                out_tr.convert2string(), exp_tr.convert2string()))
            end
        end
    endtask

    int VECT_CNT, PASS_CNT, ERROR_CNT;

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if (VECT_CNT && !ERROR_CNT) begin
            `uvm_info(
                "PASSED",
                $sformatf(
                    "\n\n\n*** TEST PASSED - %0d vectors ran, %0d vectors passed ***\n",
                    VECT_CNT, PASS_CNT
                ),
                UVM_LOW
            )
        end else begin
            `uvm_error(
                "FAILED",
                $sformatf(
                    "\n\n\n*** TEST FAILED - %0d vectors ran, %0d vectors passed, %0d vectors failed ***\n",
                    VECT_CNT, PASS_CNT, ERROR_CNT
                )
            )
        end
    endfunction

    function void PASS();
        VECT_CNT++;
        PASS_CNT++;
    endfunction

    function void ERROR();
        VECT_CNT++;
        ERROR_CNT++;
    endfunction

endclass