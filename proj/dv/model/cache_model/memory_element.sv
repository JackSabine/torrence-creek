virtual class memory_element extends uvm_object;
    protected cache_perf_transaction stats;

    function new(string name = "");
        super.new(name);
        this.stats = cache_perf_transaction::type_id::create("memory_element_stats");
    endfunction

    pure virtual function cache_response_t read(uint32_t addr, memory_operation_size_e op_size);
    pure virtual function cache_response_t write(uint32_t addr, memory_operation_size_e op_size, uint32_t data);

    virtual function cache_perf_transaction get_stats();
        return this.stats;
    endfunction
endclass
