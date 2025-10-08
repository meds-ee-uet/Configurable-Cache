// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
//Description : this file contains integrated RTL of all modules of 4 way set associative cache.
// Author:  Eman Nasar.
// Date: 5th, August, 2025.
// CACHE CONTROLLER IS SAME AS DIRECT MAPPED CACHE, 2 WAY CACHE AND N WAY CACHE

module top #(
    // General Cache Parameters
    parameter int WORD_SIZE         = 32, // bits per word
    parameter int WORDS_PER_BLOCK   = 4,  // words per block
    parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE,
    parameter int NUM_BLOCKS        = 64, // total blocks
    parameter int NUM_WAYS          = 4,
    parameter int NUM_SETS          = NUM_BLOCKS / NUM_WAYS, // 32 sets
    parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8, // in bytes
    parameter int TAG_WIDTH         = 26,
    parameter int INDEX_WIDTH       = $clog2(NUM_SETS), // indexing by set
    parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK)
)(
    input  logic clk,
    input  logic rst,

    // From CPU
    input  logic        req_valid,
    input  logic        req_type,        // 0 = Read, 1 = Write
    input  logic [WORD_SIZE-1:0] data_in,
    input  logic [31:0] address, // Could be split into tag/index/offset if decoder is used
    input logic [BLOCK_SIZE-1:0] data_out_mem,
    input logic valid_mem,
    input logic ready_mem,
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
    logic [BLOCK_SIZE-1:0]  dirty_block_in;
    

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
        .read_en_mem(read_en_mem),
      .write_en_mem(write_en_mem),
        .data_in_mem(data_out_mem),
       
        .data_in(data_in),
        .dirty_block_out(dirty_block_out),
        .hit(hit),
        .data_out(data_out),
        .dirty_bit(dirty_bit)
    );

endmodule
module cache_decoder(clk, address, tag, index, blk_offset);
    input logic clk;
    input logic [31:0] address;
    output logic [25:0] tag;
    output logic [3:0] index;
    output logic [1:0] blk_offset;
    
    
  assign tag = address[31:6];
    assign index = address[5:2];
    assign blk_offset = address[1:0];
    
endmodule
module cache_controller #(
    parameter int WORD_SIZE   = 32,
    parameter int BLOCK_SIZE  = 128,
    parameter int TAG_WIDTH   = 26,
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
     // FSM state encoding
    typedef enum logic [2:0] {
        IDLE,
        COMPARE,
        WRITE_BACK,
        WRITE_ALLOCATE,
        REFILL_DONE
    } state_t;

    state_t current_state, next_state;

    // Sequential state update
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // FSM next-state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:
                if     (req_valid)
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

            default:
                next_state = IDLE;
        endcase
    end

    // Output logic (Ready-Valid Handshake Semantics)
    always_comb begin
        // Defaults
        read_en_mem      = 0;
        write_en_mem     = 0;
        write_en         = 0;
        read_en_cache    = 0;
        write_en_cache   = 0;
        refill           = 0;
        done_cache       = 0;

        valid_cache      = 0; 
        ready_cache      = 1; // default: cache is idle, so ready to receive

        case (current_state)
            IDLE: begin
                // Do nothing
            end

            COMPARE: begin
                if (hit) begin
                    done_cache     = 1;
                    write_en_cache = req_type;
                    read_en_cache  = ~req_type;
                end else if (!dirty_bit) begin
                    read_en_mem = 1; // Request block from memory
                end else begin
                    read_en_cache = 1;
                    valid_cache = 1; // Cache wants to send data
                    ready_cache = 0; // Cache is busy sending
                end
            end

            WRITE_BACK: begin
                valid_cache = 1;
                ready_cache = 0; // Cache is busy transmitting
                
                if (ready_mem)
                    write_en_mem = 1;
                    read_en_cache = 1;
            end

            WRITE_ALLOCATE: begin
                read_en_mem  = 1;  // Memory begins to send data
                ready_cache  = 1;  // Cache ready to receive
               
                 // IMPORTANT: During this phase, memory should be sending valid data,
                // so memory must drive ready_mem = 0 (busy sending)

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

            default: ;
        endcase
    end

endmodule
// Code your design here
module cache_memory #(
    parameter int WORD_SIZE         = 32,
    parameter int WORDS_PER_BLOCK   = 4,
    parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE,
    parameter int NUM_BLOCKS        = 64,
    parameter int NUM_WAYS          = 4,
    parameter int NUM_SETS          = NUM_BLOCKS / NUM_WAYS,
    parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8,
    parameter int TAG_WIDTH         = 26,
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

    // ---------------- Tree bits ----------------
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
    } cache_info_t;

    cache_info_t info0, info1, info2, info3;

    // ---------------- Extract cache line info ----------------
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

        info2.valid = cache[index][2][0];
        info2.dirty = cache[index][2][1];
        info2.tag   = cache[index][2][TAG_WIDTH+1:2];
        info2.block = cache[index][2][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info2.hit   = info2.valid && (tag == info2.tag);

        info3.valid = cache[index][3][0];
        info3.dirty = cache[index][3][1];
        info3.tag   = cache[index][3][TAG_WIDTH+1:2];
        info3.block = cache[index][3][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info3.hit   = info3.valid && (tag == info3.tag);
    end

    assign hit = info0.hit || info1.hit || info2.hit || info3.hit;

    // ---------------- LRU replacement (function → always_comb) ----------------
    logic [1:0] lru_line;
    always_comb begin
        if (plru[index].b1 == 0) begin
            if (plru[index].b2 == 0) lru_line = 0;
            else                     lru_line = 1;
        end else begin
            if (plru[index].b3 == 0) lru_line = 2;
            else                     lru_line = 3;
        end
    end

    // ---------------- Tree update (task → always_comb) ----------------
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
