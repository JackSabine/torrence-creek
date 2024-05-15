class cache_config extends uvm_object;
    uint32_t line_size;
    uint32_t l1_cache_size;
    uint32_t l2_cache_size;
    uint32_t l2_assoc;

    `uvm_object_utils_begin(cache_config)
        `uvm_field_int(line_size,  UVM_DEFAULT | UVM_DEC)
        `uvm_field_int(l1_cache_size, UVM_DEFAULT | UVM_DEC)
        `uvm_field_int(l2_cache_size, UVM_DEFAULT | UVM_DEC)
        `uvm_field_int(l2_assoc,      UVM_DEFAULT | UVM_DEC)
    `uvm_object_utils_end

    function new (string name = "");
        super.new(name);
    endfunction

    function void set (uint32_t line_size, uint32_t l1_cache_size, uint32_t l2_cache_size, uint32_t l2_assoc);
        this.line_size = line_size;
        this.l1_cache_size = l1_cache_size;
        this.l2_cache_size = l2_cache_size;
        this.l2_assoc = l2_assoc;
    endfunction
endclass