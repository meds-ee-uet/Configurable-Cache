module cache_memory #(
    parameter int WORD_SIZE         = 32,
    parameter int WORDS_PER_BLOCK   = 4,
    parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE,
    parameter int NUM_BLOCKS        = 64,
    parameter int NUM_WAYS          = 4,
    parameter int NUM_SETS          = NUM_BLOCKS / NUM_WAYS,
    parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8,
    parameter int TAG_WIDTH         = 25,
    parameter int INDEX_WIDTH       = $clog2(NUM_SETS),
    parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK)
)(
    input  logic clk,
    input  logic [TAG_WIDTH-1:0] tag,
    input  logic [INDEX_WIDTH-1:0] index,
    input  logic [OFFSET_WIDTH-1:0] blk_offset,
    input  logic req_type,                // 0=Read , 1=Write
    input  logic read_en_cache,
    input  logic write_en_cache,
    input  logic read_en_mem,
    input  logic write_en_mem,
    input  logic [BLOCK_SIZE-1:0] data_in_mem,
    input  logic [WORD_SIZE-1:0] data_in,
    output logic [BLOCK_SIZE-1:0] dirty_block_out,
    output logic hit,
    output logic [WORD_SIZE-1:0] data_out,
    output logic dirty_bit
);   
typedef struct {
        logic b1;
        logic b2;
        logic b3;
    } tree_bits;
    
    typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;
    cache_line_t cache [NUM_SETS-1:0][3:0];
    tree_bits plru [NUM_SETS-1:0];    
    typedef struct  {
        logic valid;
        logic dirty;
        logic [TAG_WIDTH-1:0] tag;
        logic [BLOCK_SIZE-1:0] block;
        logic hit;
    } cache_info_t;    cache_info_t info0, info1, info2, info3;    
    always_comb begin
        info0.valid = cache[index][0][0];
        info0.dirty = cache[index][0][1];
        info0.tag   = cache[index][0][TAG_WIDTH+1:2];
        info0.block = cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info0.hit   = info0.valid && (tag == info0.tag);        info1.valid = cache[index][1][0];
        info1.dirty = cache[index][1][1];
        info1.tag   = cache[index][1][TAG_WIDTH+1:2];
        info1.block = cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info1.hit   = info1.valid && (tag == info1.tag);        info2.valid = cache[index][2][0];
        info2.dirty = cache[index][2][1];
        info2.tag   = cache[index][2][TAG_WIDTH+1:2];
        info2.block = cache[index][2][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info2.hit   = info2.valid && (tag == info2.tag);        info3.valid = cache[index][3][0];
        info3.dirty = cache[index][3][1];
        info3.tag   = cache[index][3][TAG_WIDTH+1:2];
        info3.block = cache[index][3][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info3.hit   = info3.valid && (tag == info3.tag);
    end    
    assign hit = info0.hit || info1.hit || info2.hit || info3.hit;    
    logic [1:0] lru_line; //LRU replacement
    always_comb begin
        if (plru[index].b1 == 0) begin
            if (plru[index].b2 == 0) lru_line = 0;
            else                     lru_line = 1;
        end else begin
            if (plru[index].b3 == 0) lru_line = 2;
            else                     lru_line = 3;
        end
    end   
    logic [2:0] plru_next;
    logic [1:0] accessed_line;

    always_comb begin
        // default hold
        plru_next = {plru[index].b1, plru[index].b2, plru[index].b3};
        case (accessed_line)
            0: begin plru_next[2] = 1; plru_next[1] = 1; end // b1=1, b2=1
            1: begin plru_next[2] = 1; plru_next[1] = 0; end // b1=1, b2=0
            2: begin plru_next[2] = 0; plru_next[0] = 1; end // b1=0, b3=1
            3: begin plru_next[2] = 0; plru_next[0] = 0; end // b1=0, b3=0
        endcase
    end
   // ---------------- Main cache control ----------------
    always_ff @(posedge clk) begin
        data_out <= '0;
        dirty_block_out<= '0;
        accessed_line <= 'x; // default, will be set on access

        if (!hit) begin // MISS
            if (!info0.valid && read_en_mem && write_en_cache) begin
                cache[index][0][0] <= 1;
                cache[index][0][1] <= 0;
                cache[index][0][TAG_WIDTH+1:2] <= tag;
                cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                accessed_line <= 0;
            end else if (!info1.valid && read_en_mem && write_en_cache) begin
                cache[index][1][0] <= 1;
                cache[index][1][1] <= 0;
                cache[index][1][TAG_WIDTH+1:2] <= tag;
                cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                accessed_line <= 1;
            end else if (!info2.valid && read_en_mem && write_en_cache) begin
                cache[index][2][0] <= 1;
                cache[index][2][1] <= 0;
                cache[index][2][TAG_WIDTH+1:2] <= tag;
                cache[index][2][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                accessed_line <= 2;
            end else if (!info3.valid && read_en_mem && write_en_cache) begin
                cache[index][3][0] <= 1;
                cache[index][3][1] <= 0;
                cache[index][3][TAG_WIDTH+1:2] <= tag;
                cache[index][3][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                accessed_line <= 3;
            
        end else if (read_en_cache && write_en_mem) begin
           case (lru_line)
             0: if (info0.dirty) begin
                 dirty_block_out <= info0.block;
                        cache[index][0][1] <= 0;
                         accessed_line <= 0;

                end
              1: if (info1.dirty) begin
                dirty_block_out <= info1.block;
                        cache[index][1][1] <= 0;
                        accessed_line <= 1;

                    end
               2: if (info2.dirty) begin
                  dirty_block_out <= info2.block;
                        cache[index][2][1] <= 0;
                        accessed_line <= 2;

                    end
               3: if (info3.dirty) begin
                  dirty_block_out <= info3.block;
                        cache[index][3][1] <= 0;
                        accessed_line <= 3;
                    end
                endcase
            
        end else if (read_en_mem && write_en_cache) begin // MISS, cache full
                case (lru_line)
                    0: if (!info0.dirty) begin
                        cache[index][0][0] <= 1;
                        cache[index][0][1] <= 0;
                        cache[index][0][TAG_WIDTH+1:2] <= tag;
                        cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                        accessed_line <= 0;
                    end 
                    1: if (!info1.dirty) begin
                        cache[index][1][0] <= 1;
                        cache[index][1][1] <= 0;
                        cache[index][1][TAG_WIDTH+1:2] <= tag;
                        cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                        accessed_line <= 1;
                    end 
                    2: if (!info2.dirty) begin
                        cache[index][2][0] <= 1;
                        cache[index][2][1] <= 0;
                        cache[index][2][TAG_WIDTH+1:2] <= tag;
                        cache[index][2][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                        accessed_line <= 2;
                    end 
                    
                    3: if (!info3.dirty) begin
                        cache[index][3][0] <= 1;
                        cache[index][3][1] <= 0;
                        cache[index][3][TAG_WIDTH+1:2] <= tag;
                        cache[index][3][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                        accessed_line <= 3;
                    end 
                endcase
            end  
        end else begin // HIT
            if (req_type && write_en_cache) begin // Write on hit
                if (info0.hit) begin
                    cache[index][0][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
                    cache[index][0][1] <= 1;
                    accessed_line <= 0;
                end else if (info1.hit) begin
                    cache[index][1][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
                    cache[index][1][1] <= 1;
                    accessed_line <= 1;
                end else if (info2.hit) begin
                    cache[index][2][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
                    cache[index][2][1] <= 1;
                    accessed_line <= 2;
                end else if (info3.hit) begin
                    cache[index][3][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
                    cache[index][3][1] <= 1;
                    accessed_line <= 3;
                end
            end else if (!req_type && read_en_cache) begin // Read on hit
                if (info0.hit) begin
                    data_out <= info0.block[blk_offset*WORD_SIZE +: WORD_SIZE];
                    accessed_line <= 0;
                end else if (info1.hit) begin
                    data_out <= info1.block[blk_offset*WORD_SIZE +: WORD_SIZE];
                    accessed_line <= 1;
                end else if (info2.hit) begin
                    data_out <= info2.block[blk_offset*WORD_SIZE +: WORD_SIZE];
                    accessed_line <= 2;
                end else if (info3.hit) begin
                    data_out <= info3.block[blk_offset*WORD_SIZE +: WORD_SIZE];
                    accessed_line <= 3;
                end
            end
        end

        // finally update PLRU bits for this set
        if (accessed_line !== 'x) begin
            plru[index].b1 <= plru_next[2];
            plru[index].b2 <= plru_next[1];
            plru[index].b3 <= plru_next[0];
        end
    end

endmodule
	
