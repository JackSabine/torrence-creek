`include "uvm_macros.svh"
`include "macros.svh"

package torrence_pkg;
    import uvm_pkg::*;
    import torrence_types::*;

    `include "dpi-c.sv"

    `include "../model/cache_model/files.sv"
    `include "../configs/cache_config.sv"
    `include "../configs/clock_config.sv"

    `include "../seq/memory_transaction.sv"
    `include "../seq/reset_transaction.sv"
    `include "../seq/cache_perf_transaction.sv"

    `include "../seq/base_access_seq.sv"
    `include "../seq/random_access_seq.sv"
    `include "../seq/memory_response_seq.sv"
    `include "../seq/reset_seq.sv"

    `include "../agents/cache_req_agent/cache_req_sequencer.sv"
    `include "../agents/cache_req_agent/cache_req_driver.sv"
    `include "../agents/cache_req_agent/cache_req_monitor.sv"
    `include "../agents/cache_req_agent/cache_req_agent.sv"

    `include "../agents/memory_rsp_agent/memory_rsp_sequencer.sv"
    `include "../agents/memory_rsp_agent/memory_rsp_driver.sv"
    `include "../agents/memory_rsp_agent/memory_rsp_monitor.sv"
    `include "../agents/memory_rsp_agent/memory_rsp_agent.sv"

    `include "../agents/reset_agent/reset_sequencer.sv"
    `include "../agents/reset_agent/reset_driver.sv"
    `include "../agents/reset_agent/reset_agent.sv"

    `include "../agents/cache_perf_agent/cache_perf_monitor.sv"
    `include "../agents/cache_perf_agent/cache_perf_agent.sv"

    `include "scoreboard.sv"
    `include "environment.sv"

    `include "tests.sv"
endpackage
