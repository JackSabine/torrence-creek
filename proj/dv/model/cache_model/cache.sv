class cache extends memory_element;
    memory_element lower_memory;

    local cache_set sets[];

    local const uint8_t num_set_bits;
    local const uint8_t num_tag_bits;
    local const uint8_t num_offset_bits;

    local const uint8_t words_per_block;

    function new (cache_type_e cache_type, uint32_t cache_size, uint32_t block_size, uint8_t associativity, memory_element lower_memory);
        uint32_t num_sets;

        super.new({"cache_model<", cache_type.name(), ">"});

        num_sets = cache_size / (block_size * associativity);

        this.lower_memory = lower_memory;
        this.num_set_bits = $clog2(num_sets);
        this.num_offset_bits = $clog2(block_size);
        this.num_tag_bits = 32 - (this.num_set_bits + this.num_offset_bits);

        this.words_per_block = block_size / 4;

        this.sets = new [num_sets];

        foreach (this.sets[i]) begin
            this.sets[i] = new(associativity, this.words_per_block);
        end

        this.stats.origin = cache_type;

        `uvm_info(
            $sformatf("cache<%s>", cache_type.name()),
            $sformatf(
                "cache_size: %0d - block_size: %0d - assoc: %0d - tag bits: %0d - set bits: %0d - ofs bits: %0d",
                cache_size, block_size, associativity, this.num_tag_bits, this.num_set_bits, this.num_offset_bits
            ),
            UVM_HIGH
        )
    endfunction

    local function uint32_t gen_bitmask(uint8_t width);
        return (1 << width) - 1;
    endfunction

    local function uint32_t get_tag(uint32_t addr);
        return addr >> (this.num_offset_bits + this.num_set_bits);
    endfunction

    local function uint32_t get_set(uint32_t addr);
        return (addr >> this.num_offset_bits) & gen_bitmask(this.num_set_bits);
    endfunction

    local function uint32_t get_ofs(uint32_t addr);
        return addr & gen_bitmask(this.num_offset_bits);
    endfunction

    local function uint32_t construct_addr(uint32_t tag, uint32_t set, uint32_t ofs);
        uint32_t addr;

        addr = 0;
        addr = (addr | tag) << num_set_bits;
        addr = (addr | set) << num_offset_bits;
        addr = (addr | ofs);
        return addr;
    endfunction

    local function uint32_t select_read_data(uint32_t read_data, memory_operation_size_e op_size, uint8_t byte_offset);
        uint32_t mask;

        unique case (op_size)
            BYTE: mask = gen_bitmask(8);
            HALF: mask = gen_bitmask(16);
            WORD: mask = gen_bitmask(32);
        endcase

        return mask & (read_data >> (8 * byte_offset));
    endfunction

    local function uint32_t insert_write_data(uint32_t read_data, uint32_t write_data, memory_operation_size_e op_size, uint8_t byte_offset);
        uint32_t mask;

        unique case (op_size)
            BYTE: mask = gen_bitmask(8);
            HALF: mask = gen_bitmask(16);
            WORD: mask = gen_bitmask(32);
        endcase

        write_data &= mask;

        mask <<= (8 * byte_offset);
        write_data <<= (8 * byte_offset);

        read_data &= ~mask;
        read_data |= write_data;

        return read_data;
    endfunction

    // Cache miss recovery
    //  1. Handles writebacks if needed, then evict the victim
    //  2. Fetch data from lower memory
    //  3. Install fetched block
    //
    // Note: the higher cache already missed, so no need to track the response is_hit field
    //
    local function void handle_miss(uint32_t tag, uint32_t set);
        cache_response_t resp;

        if (this.sets[set].is_victim_dirty()) begin
            for (int i = 0; i < this.words_per_block; i++) begin
                void'( // resp is not needed
                    this.lower_memory.write(
                        this.construct_addr(this.sets[set].get_victim_tag(), set, 4*i),
                        WORD,
                        this.sets[set].get_indexed_victim_word(i)
                    )
                );
            end

            this.sets[set].evict_victim();
            this.stats.writebacks++;
        end

        for (int i = 0; i < this.words_per_block; i++) begin
            resp = this.lower_memory.read(
                this.construct_addr(tag, set, 4*i),
                WORD
            );

            this.sets[set].set_indexed_victim_word(i, resp.req_word);
        end

        this.sets[set].install(tag);

        assert(this.sets[set].is_cached(tag)) else $fatal(1, "cache::handle_miss() did not correctly install the block");
    endfunction

    // Top-level cache read
    // 1. a. Search corresponding cache set for addr
    //    b. If missed, handle it
    // 2. Perform the read and return the word
    //
    virtual function cache_response_t read(uint32_t addr, memory_operation_size_e op_size);
        cache_response_t resp;
        uint32_t set, tag, ofs;

        this.stats.reads++;

        set = get_set(addr);
        tag = get_tag(addr);
        ofs = get_ofs(addr);

        resp.is_hit = this.sets[set].is_cached(tag);

        if (resp.is_hit) begin
            this.stats.hits++;
        end else begin
            this.handle_miss(tag, set);
            this.stats.misses++;
        end

        resp.req_word = this.sets[set].read_word(tag, ofs);
        resp.req_word = this.select_read_data(resp.req_word, op_size, addr[1:0]);

        `uvm_info("cache", $sformatf("cache::read(%H) is returning %H", addr, resp.req_word), UVM_HIGH)

        return resp;
    endfunction

    // Top-level cache write
    // 1. a. Search corresponding cache set for addr
    //    b. If missed, handle it
    // 2. Perform the write
    //
    virtual function cache_response_t write(uint32_t addr, memory_operation_size_e op_size, uint32_t data);
        cache_response_t resp;
        uint32_t set, tag, ofs;
        uint32_t word_to_write;

        this.stats.writes++;

        set = get_set(addr);
        tag = get_tag(addr);
        ofs = get_ofs(addr);

        resp.is_hit = this.sets[set].is_cached(tag);

        if (resp.is_hit) begin
            this.stats.hits++;
        end else begin
            this.handle_miss(tag, set);
            this.stats.misses++;
        end

        resp.req_word = this.sets[set].read_word(tag, ofs);

        word_to_write = this.insert_write_data(resp.req_word, data, op_size, addr[1:0]);

        this.sets[set].write_word(tag, ofs, word_to_write);

        return resp;
    endfunction
endclass