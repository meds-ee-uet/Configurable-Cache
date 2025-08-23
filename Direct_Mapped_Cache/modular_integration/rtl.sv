module top #(
   // General Cache Parameters
parameter int WORD_SIZE         = 32, // bits per word
parameter int WORDS_PER_BLOCK   = 4, // words in each cache block
parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE,  // bits per block
parameter int NUM_BLOCKS        = 64, // number of blocks in cache
parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8, // in bytes
parameter int TAG_WIDTH         = 24,
  parameter int INDEX_WIDTH       = $clog2(NUM_BLOCKS),
parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK)

)(
    input  logic clk,
    input  logic rst,

    // From CPU
    input  logic        req_valid,
    input  logic        req_type,        // 0 = Read, 1 = Write
    input  logic [WORD_SIZE-1:0] data_in,
    input  logic [31:0] address, // Could be split into tag/index/offset if decoder is used

    input  logic ready_mem,
    input  logic  valid_mem,
  input  logic [BLOCK_SIZE-1:0] data_out_mem,
    // To CPU
    output logic [WORD_SIZE-1:0] data_out,
    output logic                 done_cache
);

    // Decoder outputs
    logic [TAG_WIDTH-1:0]   tag;
    logic [INDEX_WIDTH-1:0] index;
    logic [OFFSET_WIDTH-1:0] blk_offset;

    // Cache <-> Controller signals
    logic  read_en_cache, write_en_cache;
    logic [BLOCK_SIZE-1:0] dirty_block_out;
    logic dirty_bit, hit;

    // Memory signals
    logic read_en_mem, write_en_mem;
    logic  dirty_block_in;
    

    // Instantiate Cache Controller
    cache_controller #(
        .WORD_SIZE(WORD_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .TAG_WIDTH(TAG_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH),
        .OFFSET_WIDTH(OFFSET_WIDTH)
    ) controller (
        .clk(clk),
        .rst(rst),
        .req_valid(req_valid),
        .req_type(req_type),
        .hit(hit),
        .dirty_bit(dirty_bit),

        // Memory handshake
        .ready_mem(ready_mem),
        .valid_mem(valid_mem),

        // Cache handshake
        .valid_cache(),   // Not connected yet
        .ready_cache(),   // Not connected yet

        .read_en_mem(read_en_mem),
        .write_en_mem(write_en_mem),
        .write_en(),      // Not connected
        .read_en_cache(read_en_cache),
        .write_en_cache(write_en_cache),
        .refill(),        // Not connected
        .done_cache(done_cache)
    );
    cache_decoder u_decoder (
        .clk        (clk),
        .address    (address),
        .tag        (tag),
        .index      (index),
        .blk_offset (blk_offset)
    );

    // Instantiate Cache Memory
    cache_memory #(
        .WORD_SIZE(WORD_SIZE),
        .WORDS_PER_BLOCK(WORDS_PER_BLOCK),
        .BLOCK_SIZE(BLOCK_SIZE),
        .NUM_BLOCKS(NUM_BLOCKS),
        .CACHE_SIZE(CACHE_SIZE),
        .TAG_WIDTH(TAG_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH),
        .OFFSET_WIDTH(OFFSET_WIDTH)
    ) cache (
        .clk(clk),
        .tag(tag),
        .index(index),
        .blk_offset(blk_offset),
        .req_type(req_type),
        .read_en_cache(read_en_cache),
        .write_en_cache(write_en_cache),
        .read_en_mem(read_en_mem),
        .data_in_mem(data_out_mem),
        .data_in(data_in),
        .dirty_block_out(dirty_block_out),
        .hit(hit),
        .data_out(data_out),
        .dirty_bit(dirty_bit)
    );

endmodule
module cache_decoder(clk, address, tag, index, blk_offset);
    input  logic        clk;
    input  logic [31:0] address;
    output logic [23:0] tag;
    output logic [5:0]  index;
    output logic [1:0]  blk_offset;

    
    // Actual logic
  assign tag        = address[31:8];
  assign index      = address[7:2];
  assign blk_offset = address[1:0];
endmodule

module cache_controller #(
    parameter int WORD_SIZE   = 32,
    parameter int BLOCK_SIZE  = 128,
    parameter int TAG_WIDTH   = 24,
    parameter int INDEX_WIDTH = 6,
    parameter int OFFSET_WIDTH = 2
)(
    input  logic clk,
    input  logic rst,
    input  logic req_valid,
    input  logic req_type,
    input  logic hit,
    input  logic dirty_bit,

    // Memory handshake
    input  logic ready_mem,
    input  logic valid_mem,

    // Cache handshake
    output logic valid_cache,
    output logic ready_cache,

    output logic read_en_mem,
    output logic write_en_mem,
    output logic write_en,
    output logic read_en_cache,
    output logic write_en_cache,
    output logic refill,
    output logic done_cache
);
    typedef enum logic [2:0] {
        IDLE,
        COMPARE,
        WRITE_BACK,
        WRITE_ALLOCATE,
        REFILL_DONE
    } state_t;

    state_t current_state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:
                if (req_valid)
                    next_state = COMPARE;

            COMPARE: begin
                if (hit)
                    next_state = IDLE;
                else if (!dirty_bit)
                    next_state = WRITE_ALLOCATE;
                else
                    next_state = WRITE_BACK;
            end

            WRITE_BACK:
                if (valid_cache && ready_mem)
                    next_state = WRITE_ALLOCATE;

            WRITE_ALLOCATE:
                if (valid_mem && ready_cache)
                    next_state = REFILL_DONE;

            REFILL_DONE:
                next_state = IDLE;
        endcase
    end

    always_comb begin
        read_en_mem      = 0;
        write_en_mem     = 0;
        write_en         = 0;
        read_en_cache    = 0;
        write_en_cache   = 0;
        refill           = 0;
        done_cache       = 0;

        valid_cache      = 0;
        ready_cache      = 1;

        case (current_state)
            COMPARE: begin
                if (hit) begin
                    done_cache     = 1;
                    write_en_cache = req_type;
                    read_en_cache  = ~req_type;
                end else if (!dirty_bit) begin
                    read_en_mem = 1;
                end else begin
                    read_en_cache = 1;
                    valid_cache = 1;
                    ready_cache = 0;
                end
            end

            WRITE_BACK: begin
                valid_cache = 1;
                ready_cache = 0;
                read_en_cache = 1;
                if (ready_mem)
                    write_en_mem = 1;
            end

            WRITE_ALLOCATE: begin
                read_en_mem  = 1;
                ready_cache  = 1;
                if (valid_mem && ready_cache)
                    write_en_cache = 1;
            end

            REFILL_DONE: begin
                refill = 1;
                done_cache = 1;
                if (req_type)
                    write_en_cache = 1;
                else
                    read_en_cache = 1;
            end
        endcase
    end
endmodule
module cache_memory #(
    parameter int WORD_SIZE         = 32, 
    parameter int WORDS_PER_BLOCK   = 4,  
    parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE,  
    parameter int NUM_BLOCKS        = 64, 
    parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8,
    parameter int TAG_WIDTH         = 24,
    parameter int INDEX_WIDTH       = $clog2(NUM_BLOCKS),
    parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK)
)(
    input  logic clk,
    input  logic [TAG_WIDTH-1:0] tag,
    input  logic [INDEX_WIDTH-1:0] index,
    input  logic [OFFSET_WIDTH-1:0] blk_offset,
    input  logic req_type,                
    input  logic read_en_cache,
    input  logic write_en_cache,
    input  logic read_en_mem,
    input  logic [BLOCK_SIZE-1:0] data_in_mem,
    input  logic [WORD_SIZE-1:0] data_in,
    output logic [BLOCK_SIZE-1:0] dirty_block_out,
    output logic hit,
    output logic [WORD_SIZE-1:0] data_out,
    output logic dirty_bit
);

// Typedefs
    
    typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;
    cache_line_t cache [NUM_BLOCKS-1:0];

    // Field extraction
    logic valid;
    logic [TAG_WIDTH-1:0] stored_tag;
    logic [BLOCK_SIZE-1:0] block;

    assign valid       = cache[index][0];
    assign dirty_bit   = cache[index][1];
    assign stored_tag  = cache[index][TAG_WIDTH+1:2];
    assign block       = cache[index][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];

    // HIT logic
    always_comb begin
        hit = (valid && (tag == stored_tag)) ? 1 : 0;
    end
  

    always_ff @(posedge clk) begin
      
        if (read_en_mem && write_en_cache) begin
            cache[index][0] <= 1'b1;
            cache[index][1] <= 1'b0;
            cache[index][TAG_WIDTH+1:2] <= tag;
            cache[index][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
            
        end 
        else if (req_type && hit && write_en_cache) begin
            cache[index][BLOCK_SIZE + TAG_WIDTH + 1 - blk_offset*WORD_SIZE -: WORD_SIZE] <= data_in;
            cache[index][1] <= 1'b1;
            
        end 
        else if (!req_type && hit && read_en_cache) begin
            data_out <= cache[index][BLOCK_SIZE + TAG_WIDTH + 1 - blk_offset*WORD_SIZE -: WORD_SIZE];
           
        end 
        else begin
            data_out <= '0;
        end

        if (dirty_bit && !hit && read_en_cache) begin
            dirty_block_out <= block;
        end else begin
            dirty_block_out <= '0;
        end
    end

endmodule