// Code your design here
module cache_memory #(
// General Cache Parameters
parameter int WORD_SIZE         = 32, // bits per word
parameter int WORDS_PER_BLOCK   = 4,  // words per block
parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE,
parameter int NUM_BLOCKS        = 64, // total blocks
parameter int NUM_WAYS          = 2,
parameter int NUM_SETS          = NUM_BLOCKS / NUM_WAYS, // 32 sets
parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8, // in bytes
parameter int TAG_WIDTH         = 25,
parameter int INDEX_WIDTH       = $clog2(NUM_SETS), // indexing by set
parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK)

// Cache line format: {valid, dirty/plru, tag, block_data}
)

    (
    input  logic clk,
    input  logic [TAG_WIDTH-1:0] tag,
    input  logic [INDEX_WIDTH-1:0] index,
    input  logic [OFFSET_WIDTH-1:0] blk_offset,
    input  logic req_type,                // 0=Read , 1=Write
    input  logic read_en_cache,
    input  logic write_en_cache,
    input  logic [BLOCK_SIZE-1:0] data_in_mem,
    input  logic [WORD_SIZE-1:0] data_in,
    output logic [BLOCK_SIZE-1:0] dirty_block_out,
    output logic hit,
    output logic [WORD_SIZE-1:0] data_out,
    output logic dirty_bit
);
    typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;
    // 2-way set associative cache
    cache_line_t cache [NUM_SETS-1:0][1:0];  // [index][way]

    // PLRU replacement policy
    logic plru [NUM_SETS-1:0];
    // Define per-way cache info struct
    
    typedef struct packed {
        logic valid;
        logic dirty;
        logic [TAG_WIDTH-1:0] tag;
        logic [BLOCK_SIZE-1:0] block;
        logic hit;
    } cache_info_t; 
    cache_info_t info0, info1;

    // Assign per-way values to struct fields
    always_comb begin
        info0.valid = cache[index][0][0];
        info0.dirty = cache[index][0][1];
        info0.tag   = cache[index][0][TAG_WIDTH+1:2];
        info0.block = cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info0.hit   = info0.valid && (tag == info0.tag);

        info1.valid = cache[index][1][0];
        info1.dirty = cache[index][1][1];
        info1.tag   = cache[index][1][TAG_WIDTH+1:2];
        info1.block = cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];

      info1.hit   = info1.valid && (tag == info1.tag);
    
    end

    assign hit = info0.hit || info1.hit;

    always_ff @(posedge clk) begin
        data_out <= '0;
        dirty_block_out <= '0;

        if (!hit) begin
          if (!info0.valid && read_en_mem && write_en_cache) begin
                // Refill into way 0
                cache[index][0][0] <= 1;
                cache[index][0][1] <= 0;
                cache[index][0][TAG_WIDTH+1:2] <= tag;
                cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                plru[index] <= 1;

          end else if (!info1.valid && read_en_mem && write_en_cache) begin
                // Refill into way 1
                cache[index][1][0] <= 1;
                cache[index][1][1] <= 0;
                cache[index][1][TAG_WIDTH+1:2] <= tag;
                cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                plru[index] <= 0;

            end 
          else if (info0.valid && plru[index] == 0 && !info0.dirty && read_en_mem && write_en_cache) begin
                cache[index][0][0] <= 1;
                cache[index][0][1] <= 0;
                cache[index][0][TAG_WIDTH+1:2] <= tag;
                cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                plru[index] <= 1;

          end else if (info1.valid && plru[index] == 1 && !info1.dirty && read_en_mem && write_en_cache) begin
                cache[index][1][0] <= 1;
                cache[index][1][1] <= 0;
                cache[index][1][TAG_WIDTH+1:2] <= tag;
                cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                plru[index] <= 0;

          end else if (info0.valid && plru[index] == 0 && info0.dirty && read_en_cache && write_en_mem) begin
                dirty_block_out <= info0.block;
                cache[index][1][1] <= 0;

          end else if (info1.valid && plru[index] == 1 && info1.dirty && read_en_cache && write_en_cache) begin
                dirty_block_out <= info1.block;
                cache[index][1][1] <= 0;
            end

        end else if (req_type && hit ) begin
 
          // Write on hit
            if (info0.hit && write_en_cache) begin
                cache[index][0][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
                cache[index][0][1] <= 1;
                plru[index] <= 1;

          end else if (info1.hit && write_en_cache) begin
                cache[index][1][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
                cache[index][1][1] <= 1;
                plru[index] <= 0;
            end

        end else if (!req_type && hit ) begin
            // Read on hit
          if (info0.hit && read_en_cache) begin
                data_out <= info0.block[blk_offset*WORD_SIZE +: WORD_SIZE];
                plru[index] <= 1;

          end else if (info1.hit && read_en_cache) begin
                data_out <= info1.block[blk_offset*WORD_SIZE +: WORD_SIZE];
                plru[index] <= 0;
            end
        end
    end
endmodule
