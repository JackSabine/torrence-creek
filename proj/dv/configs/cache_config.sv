class cache_config extends uvm_object;
    uint32_t line_size;
    uint32_t icache_size;
    uint32_t icache_assoc;
    uint32_t dcache_size;
    uint32_t dcache_assoc;
    uint32_t l2_size;
    uint32_t l2_assoc;

    `uvm_object_utils_begin(cache_config)
        `uvm_field_int(line_size,    UVM_DEFAULT | UVM_DEC)
        `uvm_field_int(icache_size,  UVM_DEFAULT | UVM_DEC)
        `uvm_field_int(icache_assoc, UVM_DEFAULT | UVM_DEC)
        `uvm_field_int(dcache_size,  UVM_DEFAULT | UVM_DEC)
        `uvm_field_int(dcache_assoc, UVM_DEFAULT | UVM_DEC)
        `uvm_field_int(l2_size,      UVM_DEFAULT | UVM_DEC)
        `uvm_field_int(l2_assoc,     UVM_DEFAULT | UVM_DEC)
    `uvm_object_utils_end

    function new (string name = "");
        super.new(name);
    endfunction

    function void set (
        uint32_t line_size,
        uint32_t icache_size,
        uint32_t icache_assoc,
        uint32_t dcache_size,
        uint32_t dcache_assoc,
        uint32_t l2_size,
        uint32_t l2_assoc
    );
        this.line_size = line_size;
        this.icache_size = icache_size;
        this.icache_assoc = icache_assoc;
        this.dcache_size = dcache_size;
        this.dcache_assoc = dcache_assoc;
        this.l2_size = l2_size;
        this.l2_assoc = l2_assoc;
    endfunction
endclass
