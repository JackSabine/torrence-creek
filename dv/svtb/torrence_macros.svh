`ifndef TORRENCE_MACROS__SVH
  `define TORRENCE_MACROS__SVH

`define WORD        (32)
`define HALF        (16)
`define BYTE        (8)
`define BYTES_PER_WORD ((`WORD) / (`BYTE))
`define HALFS_PER_WORD ((`WORD) / (`HALF))

`define print_uvm_factory(PRINT_ALL_TYPES=1) uvm_factory::get().print(.all_types(PRINT_ALL_TYPES));

`define RO_RW_MEMORY_BOUNDARY (32'h8000_0000)

`endif