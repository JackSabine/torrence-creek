virtual class memory_element;
    protected cache_perf_transaction stats;

    function new();
        this.stats = cache_perf_transaction::type_id::create("memory_element_stats");
    endfunction

    pure virtual function cache_response_t read(uint32_t addr);
    pure virtual function cache_response_t write(uint32_t addr, uint32_t data);

    virtual function cache_perf_transaction get_stats();
        return this.stats;
    endfunction
endclass
