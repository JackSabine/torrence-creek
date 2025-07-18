class main_memory extends memory_element;
    local uint32_t memory [uint32_t];

    function new(string name = "");
        super.new(name);
    endfunction

    local function uint32_t compute_default_value(uint32_t addr);
        uint32_t result;

        result = 0;
        while (addr != 0) begin
            result = (result * 16) + (addr % 16);
            addr = addr / 16;
        end

        return result;
    endfunction

    virtual function cache_response_t read(uint32_t addr, memory_operation_size_e op_size);
        cache_response_t resp;

        resp.is_hit = 1'b1;
        resp.req_word = memory.exists(addr) ?
            memory[addr] :
            compute_default_value(addr);

        this.stats.reads++;

        return resp;
    endfunction


    virtual function cache_response_t write(uint32_t addr, memory_operation_size_e op_size, uint32_t data);
        cache_response_t resp;

        resp.is_hit = 1'b1;
        resp.req_word = memory.exists(addr) ?
            memory[addr] :
            compute_default_value(addr);

        memory[addr] = data;

        this.stats.writes++;

        return resp;
    endfunction

    function void tb_write(uint32_t addr, uint32_t data);
        memory[addr] = data;
    endfunction
endclass