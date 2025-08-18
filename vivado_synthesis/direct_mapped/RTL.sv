module top #(
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
)(
    input  logic clk,
    input  logic rst,

    // From CPU (control)
    input  logic        req_valid,
    input  logic        req_type,        // 0 = Read, 1 = Write

    // Nibble-based data input from switches/buttons
    input  logic [3:0]  nibble_value,    // SW0-SW3
    input  logic [2:0]  nibble_select,   // SW4-SW6 (select nibble index 0-7)
    input  logic        mode_select,    // SW7 (0=data_in, 1=address)
    input  logic        load_nibble,     // BTN0 to load nibble

    // Address input (still full 32-bit from switches/UART/etc.)
   
   output logic [15:0] leds,// for data_oout

    // To CPU
    //output logic [WORD_SIZE-1:0] data_out,
    output logic                 done_cache
);

    // Internal register to hold full 32-bit data_in assembled from nibbles
    logic [31:0] data_in_reg;
    logic [31:0] data_out_cache;  // from cache_memory
    logic [31:0] address_reg;

   // -----------------------------------
    // Nibble loader for data and address
    // -----------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_reg <= 32'b0;
            address_reg <= 32'b0;
        end else if (load_nibble) begin
            if (!mode_select) begin
                // Loading into data_in
                data_in_reg[nibble_select*4 +: 4] <= nibble_value;
            end else begin
                // Loading into address
                address_reg[nibble_select*4 +: 4] <= nibble_value;
            end
        end
    end

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
    logic [BLOCK_SIZE-1:0] data_out_mem, dirty_block_in;
    logic ready_mem, valid_mem;

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
        .address    (address_reg),
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
        .NUM_WAYS(NUM_WAYS),
        .NUM_SETS(NUM_SETS),
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
        .data_in_mem(data_out_mem),
        .data_in(data_in_reg), // <- Using assembled 32-bit value
        .dirty_block_out(dirty_block_out),
        .hit(hit),
        .data_out     (data_out_cache), // connect here
        .dirty_bit(dirty_bit)
    );

endmodule

module cache_decoder(clk, address, tag, index, blk_offset);
    input logic clk;
    input logic [31:0] address;
    output logic [24:0] tag;
    output logic [4:0] index;
    output logic [1:0] blk_offset;
    
    
    assign tag = address[31:7];
    assign index = address[6:2];
    assign blk_offset = address[1:0];
    
endmodule
module cache_controller #(
    parameter int WORD_SIZE   = 32,
    parameter int BLOCK_SIZE  = 128,
    parameter int TAG_WIDTH   = 25,
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

    always_ff @(posedge clk) begin
    if (rst)
        current_state <= IDLE;
    else begin
        if (current_state != next_state)
            
        current_state <= next_state;
    end
end

    always_comb begin
    next_state = current_state;
    case (current_state)
        IDLE: begin
            if (req_valid) begin
                
                next_state = COMPARE;
            end
        end

        COMPARE: begin
          
            if (hit)
                next_state = IDLE;
            else if (!dirty_bit)
                next_state = WRITE_ALLOCATE;
            else
                next_state = WRITE_BACK;
        end
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
    input  logic read_en_mem,
    input  logic write_en_mem,
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