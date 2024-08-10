class cache_perf_transaction extends uvm_sequence_item;
    `uvm_object_utils(cache_perf_transaction)

    uint32_t hits;
    uint32_t misses;
    uint32_t reads;
    uint32_t writes;

    l1_type_e origin;

    function new(string name = "");
        super.new(name);
    endfunction

    function string convert2string();
        string s;
        s = $sformatf(
            {
                "%0s performance counters:\n",
                "* hits  : %0d\n",
                "* misses: %0d\n",
                "* reads : %0d\n",
                "* writes: %0d\n"
            },
            origin.name(),
            hits,
            misses,
            reads,
            writes
        );
        return s;
    endfunction

    virtual function void do_copy(uvm_object rhs);
        cache_perf_transaction _obj;
        $cast(_obj, rhs);

        hits   = _obj.hits;
        misses = _obj.misses;
        reads  = _obj.reads;
        writes = _obj.writes;
        origin = _obj.origin;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        cache_perf_transaction _obj;
        $cast(_obj, rhs);

        return
            hits   == _obj.hits   &
            misses == _obj.misses &
            reads  == _obj.reads  &
            writes == _obj.writes &
            origin == _obj.origin ;
    endfunction
endclass
