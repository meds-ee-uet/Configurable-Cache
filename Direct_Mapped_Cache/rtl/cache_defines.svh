// cache_defines.svh

`ifndef CACHE_DEFINES_SVH
`define CACHE_DEFINES_SVH

// General Cache Parameters
parameter int WORD_SIZE         = 32; // bits per word
parameter int WORDS_PER_BLOCK   = 4;  // words in each cache block
parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE;  // bits per block
parameter int NUM_BLOCKS        = 64; // number of blocks in cache
parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8; // in bytes
parameter int TAG_WIDTH         = 24;
parameter int INDEX_WIDTH       = $clog2(NUM_BLOCKS);
parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK);

// Typedefs
typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;

`endif
