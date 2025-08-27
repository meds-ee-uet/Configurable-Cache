// ============================================================
// cache_defines.svh
// Common parameters, typedefs, and macros for cache RTL
// ============================================================

`ifndef CACHE_DEFINES_SVH
`define CACHE_DEFINES_SVH

// -------------------- Global Parameters --------------------
parameter int ADDR_WIDTH       = 32;
parameter int WORD_SIZE        = 32;
parameter int WORDS_PER_BLOCK  = 4;
parameter int NUM_BLOCKS       = 64;
parameter int NUM_WAYS         = 2;     // MUST be power of 2 >= 2

// Derived parameters
parameter int BLOCK_SIZE   = WORD_SIZE * WORDS_PER_BLOCK;
parameter int BLOCK_BYTES  = BLOCK_SIZE / 8;
parameter int OFFSET_WIDTH = $clog2(WORDS_PER_BLOCK);
parameter int INDEX_WIDTH  = $clog2(NUM_BLOCKS / NUM_WAYS);
parameter int TAG_WIDTH    = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;
parameter int NUM_SETS     = NUM_BLOCKS / NUM_WAYS;
parameter int CACHE_SIZE   = NUM_BLOCKS * BLOCK_SIZE / 8;

// -------------------- FSM States --------------------
typedef enum logic [2:0] {
    IDLE,
    COMPARE,
    WRITE_BACK,
    WRITE_ALLOCATE,
    REFILL_DONE
} cache_state_t;

// -------------------- Cache Line Format --------------------
// Layout: { block [BLOCK_SIZE-1:0], tag [TAG_WIDTH-1:0], dirty, valid }
typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;

// -------------------- Per-Way Cache Info Struct --------------------
typedef struct packed {
    logic                  valid;
    logic                  dirty;
    logic [TAG_WIDTH-1:0]  tag;
    logic [BLOCK_SIZE-1:0] block;
    logic                  hit;
} cache_info_t;

`endif // CACHE_DEFINES_SVH
