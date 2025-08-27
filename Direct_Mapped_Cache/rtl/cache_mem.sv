// ============================================================================
// Module: cache_memory
// Description:
//   Implements a simplified cache memory structure with support for:
//     - Read/Write requests
//     - Cache refill from memory
//     - Dirty-bit management (for write-back)
//     - Tag, index, block, and hit checking
//
//   Cache line format (per entry in `cache`):
//   --------------------------------------------------------------
//   | Valid (1) | Dirty (1) | Tag (TAG_WIDTH) | Data Block (BLOCK_SIZE) |
//   --------------------------------------------------------------
//     MSB -----------------------------------------------------------------> LSB
//
// Ports:
//   clk              : System clock
//   tag              : Tag portion of incoming address
//   index            : Index portion of incoming address
//   blk_offset       : Word offset inside cache block
//   req_type         : Request type (0 = Read, 1 = Write)
//   read_en_cache    : Enable read request to cache
//   write_en_cache   : Enable write request to cache
//   refill           : Signal that new block is fetched from memory
//   data_in_mem      : New block fetched from memory (on refill)
//   data_in          : Single word input (for write operations)
//   dirty_block_out  : Output block when dirty block needs write-back
//   hit              : Indicates whether request was a cache hit
//   data_out         : Word output (on read hit)
//   dirty_bit        : Dirty status of the accessed cache line
//   done_cache       : Operation completion flag
// ============================================================================

`include "cache_defines.svh"

module cache_memory #() (
    input  logic clk,
    input  logic [TAG_WIDTH-1:0] tag,            // Input tag from address
    input  logic [INDEX_WIDTH-1:0] index,        // Input index from address
    input  logic [OFFSET_WIDTH-1:0] blk_offset,  // Block offset (word select)
    input  logic req_type,                       // 0 = Read, 1 = Write
    input  logic read_en_cache,                  // Read enable
    input  logic write_en_cache,                 // Write enable
    input  logic refill,                         // Refill trigger from memory
    input  logic [BLOCK_SIZE-1:0] data_in_mem,   // Block data from memory
    input  logic [WORD_SIZE-1:0] data_in,        // Single word input
    output logic [BLOCK_SIZE-1:0] dirty_block_out, // Output for dirty block (on eviction)
    output logic hit,                            // Hit signal
    output logic [WORD_SIZE-1:0] data_out,       // Data output (for read)
    output logic dirty_bit,                      // Dirty bit status
    output logic done_cache                      // Operation done flag
);

    // =========================================================================
    // Cache memory array
    // Each entry = {valid, dirty, tag, block data}
    // =========================================================================
    cache_line_t cache [NUM_BLOCKS-1:0];

    // =========================================================================
    // Field extraction from selected cache line
    // =========================================================================
    logic valid;
    logic [TAG_WIDTH-1:0] stored_tag;
    logic [BLOCK_SIZE-1:0] block;

    assign valid       = cache[index][0];                                    // Valid bit
    assign dirty_bit   = cache[index][1];                                    // Dirty bit
    assign stored_tag  = cache[index][TAG_WIDTH+1:2];                        // Stored tag
    assign block       = cache[index][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]; // Data block

    // =========================================================================
    // HIT logic
    // =========================================================================
    always_comb begin
        hit = (valid && (tag == stored_tag)) ? 1 : 0;  // Hit if valid + tag match
    end

    // =========================================================================
    // Main cache operations
    // =========================================================================
    always_ff @(posedge clk) begin
        done_cache <= 0;  // Reset done signal each cycle

        // ----------------------------------------------------------
        // REFILL from memory (load new block into cache line)
        // Condition: read enabled + write enabled (possible bug: should this be refill?)
        // ----------------------------------------------------------
        if (read_en_mem && write_en_cache) begin
            cache[index][0] <= 1'b1;                            // Set valid
            cache[index][1] <= 1'b0;                            // Clear dirty
            cache[index][TAG_WIDTH+1:2] <= tag;                 // Update tag
            cache[index][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem; // Load block
            done_cache <= 1;
        end 

        // ----------------------------------------------------------
        // WRITE HIT (update word inside cache line, mark dirty)
        // ----------------------------------------------------------
        else if (req_type && hit && write_en_cache) begin
            cache[index][BLOCK_SIZE + TAG_WIDTH + 1 - blk_offset*WORD_SIZE -: WORD_SIZE] <= data_in;
            cache[index][1] <= 1'b1;    // Set dirty bit
            done_cache <= 1;
        end 

        // ----------------------------------------------------------
        // READ HIT (return word from cache line)
        // ----------------------------------------------------------
        else if (!req_type && hit && read_en_cache) begin
            data_out <= cache[index][BLOCK_SIZE + TAG_WIDTH + 1 - blk_offset*WORD_SIZE -: WORD_SIZE];
            done_cache <= 1;
        end 

        // ----------------------------------------------------------
        // MISS case: clear data_out until handled externally
        // ----------------------------------------------------------
        else begin
            data_out <= '0;
        end

        // ----------------------------------------------------------
        // DIRTY BLOCK OUTPUT (on eviction: when dirty & miss on read)
        // ----------------------------------------------------------
        if (dirty_bit && !hit && read_en_cache) begin
            dirty_block_out <= block;   // Output block for write-back
        end else begin
            dirty_block_out <= '0;
        end
    end

endmodule
