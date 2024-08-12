package torrence_types;
    typedef enum logic[1:0] {
        BYTE = 2'b00,
        HALF,
        WORD
    } memory_operation_size_e;

    typedef enum logic [1:0] {
        STORE = 2'b00,
        LOAD = 2'b01,
        CLFLUSH = 2'b11,
        MO_UNKNOWN = 2'bxx
    } memory_operation_e;

    typedef enum bit [1:0] {
        UNASSIGNED,
        ICACHE,
        DCACHE,
        L2CACHE
    } cache_type_e;

    typedef int unsigned uint32_t;
    typedef byte uint8_t;
endpackage
