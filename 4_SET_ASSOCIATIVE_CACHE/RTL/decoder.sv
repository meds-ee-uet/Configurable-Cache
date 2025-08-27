//==============================================================
//  Module: cache_decoder
//  Function: Decodes a 32-bit memory address into tag, index,
//            and block offset fields for a cache.
//==============================================================

module cache_decoder(
    input  logic clk,             // Clock signal (not directly used in this module,
                                  // but kept for compatibility with synchronous logic)
    input  logic [31:0] addr,     // 32-bit memory address input
    output logic [25:0] tag,      // Tag bits (upper portion of the address)
    output logic [3:0]  index,    // Index bits (used to select a specific cache set)
    output logic [1:0]  blk_offset // Block offset (selects word inside the cache block)
);

    // Extract tag: [31:6] = 26 bits
    // Identifies the unique memory block stored in cache.
    assign tag = addr[31:6];

    // Extract index: [5:2] = 4 bits
    // Chooses one of the 16 cache sets (2^4 = 16).
    assign index = addr[5:2];

    // Extract block offset: [1:0] = 2 bits
    // Chooses one of 4 words within a cache block.
    assign blk_offset = addr[1:0];
    
endmodule
