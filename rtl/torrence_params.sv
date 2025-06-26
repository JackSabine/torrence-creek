package torrence_params;
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

    parameter LINE_SIZE = 32;
    parameter ICACHE_SIZE = 1024;
    parameter ICACHE_ASSOC = 1;
    parameter DCACHE_SIZE = 1024;
    parameter DCACHE_ASSOC = 1;
    parameter L2_SIZE = 4096;
    parameter L2_ASSOC = 4;
    parameter XLEN = 32;
endpackage
