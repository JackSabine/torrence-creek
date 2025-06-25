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

    function void generate_block_mask_and_offset_mask(
        input cache_type_e cache_type,
        output uint32_t block_mask,
        output uint32_t offset_mask
    );
        offset_mask = $clog2(line_size);  // line_size (e.g. 32 --> 5)
        offset_mask = (1 << offset_mask); // (1 << 5) --> 00100000
        offset_mask = (offset_mask - 1);  // (00100000 - 1) --> 00011111 (five 1's)

        block_mask = ~offset_mask;        // (~00011111) --> 11100000
    endfunction

    function void generate_set_mask(
        input cache_type_e cache_type,
        output uint32_t set_mask
    );
        uint32_t set_count;

        case (cache_type)
            ICACHE:  set_count = icache_size / (icache_assoc * line_size);
            DCACHE:  set_count = dcache_size / (dcache_assoc * line_size);
            L2CACHE: set_count = l2_size / (l2_assoc * line_size);
            default: set_count = 0;
        endcase

        set_mask = $clog2(set_count);   // How many bits (N) wide is the set part of an address
        set_mask = (1 << set_mask) - 1; // Make a mask N-bits wide

        set_mask <<= $clog2(line_size); // Shift set mask to the middle (left of offset bits)
    endfunction
endclass
