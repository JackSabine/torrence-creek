class cache_wrapper;
    local cache icache, dcache;
    local cache l2cache;
    local main_memory memory;

    local memory_element cache_handles[cache_type_e];

    function new (cache_config cfg);
        memory = new;
        l2cache = new(L2CACHE, cfg.l2_size, cfg.line_size, cfg.l2_assoc, memory);
        icache = new(ICACHE, cfg.icache_size, cfg.line_size, cfg.icache_assoc, l2cache);
        dcache = new(DCACHE, cfg.dcache_size, cfg.line_size, cfg.dcache_assoc, l2cache);

        cache_handles[ICACHE] = icache;
        cache_handles[DCACHE] = dcache;
        cache_handles[L2CACHE] = l2cache;
    endfunction

    function cache_response_t read(uint32_t addr, cache_type_e cache_type);
        cache_response_t resp;

        case (cache_type)
            ICACHE: resp = icache.read(addr);
            DCACHE: resp = dcache.read(addr);
            default: `uvm_fatal("cache_wrapper::read", $sformatf("unimplemented cache_type %s", cache_type.name()))
        endcase

        `uvm_info("cache_wrapper", $sformatf("l1.read(%8H) returned %8H (hit = %B)", addr, resp.req_word, resp.is_hit), UVM_HIGH)
        return resp;
    endfunction

    function cache_response_t write(uint32_t addr, uint32_t data, cache_type_e cache_type);
        cache_response_t resp;

        case (cache_type)
            ICACHE: resp = icache.write(addr, data);
            DCACHE: resp = dcache.write(addr, data);
            default: `uvm_fatal("cache_wrapper::write", $sformatf("unimplemented cache_type %s", cache_type.name()))
        endcase

        return resp;
    endfunction

    function cache_perf_transaction get_stats(input cache_type_e cache_type);
        if (!cache_handles.exists(cache_type)) begin
            `uvm_fatal("cache_wrapper::get_stats", {"tried to index a cache_type ", cache_type.name(), " that wasn't in cache_handles"})
        end

        return cache_handles[cache_type].get_stats();
    endfunction

    function uint32_t get_num_caches();
        return cache_handles.size();
    endfunction
endclass