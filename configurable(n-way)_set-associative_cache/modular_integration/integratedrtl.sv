// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: This file contains the RTL code of n way integrated cache modules.
//
// Author: Ayesha Anwar.
// Date: 17th, August, 2025.
// Code your design here
module cache_top #(
    parameter int ADDR_WIDTH       = 32,
    parameter int WORD_SIZE        = 32,
    parameter int WORDS_PER_BLOCK  = 4,
    parameter int NUM_BLOCKS       = 64,
    parameter BLOCK_SIZE =           WORD_SIZE * WORDS_PER_BLOCK,
    parameter int NUM_WAYS         = 4
)(
    
    input  logic                    clk,
    input  logic                    rst,

    // Request interface
    input  logic                    req_valid,   // request valid
    input  logic                    req_type,    // 0=read, 1=write
    input  logic [ADDR_WIDTH-1:0]   addr,
    input logic [BLOCK_SIZE-1:0] data_out_mem,
    input logic valid_mem,
     input logic ready_mem,
    input  logic [WORD_SIZE-1:0]    data_in,     // for write
    output logic [WORD_SIZE-1:0]    data_out,    // for read
    output logic                    done_cache // operation complete

);

    // ============================================================
    // Derived parameters
    // ============================================================
    
    localparam int BLOCK_BYTES  = BLOCK_SIZE / 8;
   localparam int OFFSET_WIDTH = $clog2(WORDS_PER_BLOCK); // 2
localparam int INDEX_WIDTH  = $clog2(NUM_BLOCKS / NUM_WAYS); // 4
localparam int TAG_WIDTH    = ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH; // 26

 
    logic [INDEX_WIDTH-1:0]  index;
    logic [TAG_WIDTH-1:0]    tag;
    logic [OFFSET_WIDTH-1:0] blk_offset;
      // Cache <-> Controller signals
    logic  read_en_cache, write_en_cache;
    logic [BLOCK_SIZE-1:0] dirty_block_out;
    logic dirty_bit, hit;

    // Memory signals
    logic read_en_mem, write_en_mem;
    logic [BLOCK_SIZE-1:0]  dirty_block_in;
    cache_decoder u_decoder (
        .clk        (clk),
        .addr    (addr),
        .tag        (tag),
        .index      (index),
        .blk_offset (blk_offset)
    );

    // ============================================================
    // Cache Controller
    // ============================================================
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

        .ready_mem(ready_mem),
        .valid_mem(valid_mem),

        .valid_cache(valid_cache),
        .ready_cache(ready_cache),

        .read_en_mem(read_en_mem),
        .write_en_mem(write_en_mem),
        .write_en(write_en),
        .read_en_cache(read_en_cache),
        .write_en_cache(write_en_cache),
        .refill(refill),
        .done_cache(done_cache)
    );

    // ============================================================
    // Cache Memory
    // ============================================================
    cache_memory #(
        .WORD_SIZE(WORD_SIZE),
        .WORDS_PER_BLOCK(WORDS_PER_BLOCK),
        .BLOCK_SIZE(BLOCK_SIZE),
        .NUM_BLOCKS(NUM_BLOCKS),
        .NUM_WAYS(NUM_WAYS)
    ) cache (
        .clk(clk),
        .tag(tag),
        .index(index),
        .blk_offset(blk_offset),
        .req_type(req_type),

        // handshake/control from controller
        .read_en_cache(read_en_cache),
        .write_en_cache(write_en_cache),
        .read_en_mem(read_en_mem),
        .write_en_mem(write_en_mem),

        // data paths
      .data_in_mem(data_out_mem),
        .data_in(data_in),
        .dirty_block_out(dirty_block_out),
        .hit(hit),
        .data_out(data_out),
        .dirty_bit(dirty_bit)
    );

endmodule



module cache_decoder(clk, addr, tag, index, blk_offset);
    input logic clk;
    input logic [31:0] addr;
  output logic [25:0] tag;
  output logic [3:0] index;
    output logic [1:0] blk_offset;
    
    
  assign tag = addr[31:6];
  assign index = addr[5:2];
    assign blk_offset = addr[1:0];
    
endmodule

 
module cache_controller #(
    parameter int WORD_SIZE   = 32,
    parameter int BLOCK_SIZE  = 128,
    parameter int TAG_WIDTH   = 26,
    parameter int INDEX_WIDTH = 4,
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
            ready_cache = 1;
            read_en_mem    = 1;
            if (valid_mem && ready_cache) begin
                 write_en_cache = 1;
                 
               end
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
module cache_memory #(
    parameter int WORD_SIZE         = 32,
    parameter int WORDS_PER_BLOCK   = 4,
    parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE,
    parameter int NUM_BLOCKS        = 64,
    parameter int NUM_WAYS     = 4,              // MUST be power of two >= 2
    parameter int NUM_SETS         = NUM_BLOCKS / NUM_WAYS,
    parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8,
  parameter int INDEX_WIDTH       = $clog2(NUM_SETS),
  parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK),
  parameter int TAG_WIDTH         = 32 - ( INDEX_WIDTH +  OFFSET_WIDTH ) 
    
)(
    input  logic                       clk,
    input  logic [TAG_WIDTH-1:0]       tag,
    input  logic [INDEX_WIDTH-1:0]     index,
    input  logic [OFFSET_WIDTH-1:0]    blk_offset,
    input  logic                       req_type,        // 0 = Read, 1 = Write
    input  logic                       read_en_cache,
    input  logic                       write_en_cache,
    input  logic                       read_en_mem,
    input  logic                       write_en_mem,
    input  logic [BLOCK_SIZE-1:0]      data_in_mem,     // block from memory (refill)
    input  logic [WORD_SIZE-1:0]       data_in,         // word for write hits
    output logic [BLOCK_SIZE-1:0]      dirty_block_out, // block to write back
    output logic                       hit,
    output logic [WORD_SIZE-1:0]       data_out,
    output logic                       dirty_bit
);

    // ------------------------------ Parameters & Types ------------------------------
    localparam int DEPTH      = (NUM_WAYS > 1) ? $clog2(NUM_WAYS) : 1;
    localparam int TREE_BITS  = NUM_WAYS - 1; // number of PLRU bits per set

    // Compile-time check: NUM_WAYS must be a power of two and >= 2
    initial begin
        if (NUM_WAYS < 2 || (NUM_WAYS & (NUM_WAYS - 1)) != 0) begin
            $error("NUM_WAYS (%0d) must be a power of two and >= 2", NUM_WAYS);
        end
    end

    typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;

    // [index][way]
    cache_line_t cache [NUM_SETS-1:0][NUM_WAYS-1:0];

    // PLRU tree bits per set, stored in binary-heap order (node 0 = root)
    // Convention: bit == 0  -> LEFT subtree is LRU
    //             bit == 1  -> RIGHT subtree is LRU
    logic [TREE_BITS-1:0] plru [NUM_SETS-1:0];

    typedef struct packed {
        logic                  valid;
        logic                  dirty;
        logic [TAG_WIDTH-1:0]  tag;
        logic [BLOCK_SIZE-1:0] block;
        logic                  hit;
    } cache_info_t;

    cache_info_t info   [NUM_WAYS-1:0];

    // ------------------------------ Decode lines to info[] ------------------------------
   // -----------------------------------------------------
// Per-way decode
// -----------------------------------------------------
genvar w;
generate
    for (w = 0; w < NUM_WAYS; w++) begin : decode_lines
        always_comb begin
            info[w].valid = cache[index][w][0];
            info[w].dirty = cache[index][w][1];
            info[w].tag   = cache[index][w][TAG_WIDTH+1:2];
            info[w].block = cache[index][w][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
            info[w].hit   = (info[w].valid == 1'b1) && (tag == info[w].tag);
        end
    end
endgenerate

// -----------------------------------------------------
// Reduce hit/dirty across all ways
// -----------------------------------------------------
logic hit_comb, dirty_comb;

always_comb begin
    hit_comb   = 1'b0;
    dirty_comb = 1'b0;

    for (int i = 0; i < NUM_WAYS; i++) begin
        if (info[i].hit == 1'b1) begin
            hit_comb = 1'b1;
        end
        if (info[i].dirty == 1'b1) begin
            dirty_comb = 1'b1;
        end
    end
end

assign hit       = hit_comb;
assign dirty_bit = dirty_comb;


    // Return first invalid way, or -1 if none
    function automatic int first_invalid_way();
        for (int i = 0; i < NUM_WAYS; i++) begin
            if (!info[i].valid) return i;
        end
        return -1;
    endfunction

    // Pick victim way from PLRU bits (heap order). See convention above.
    function automatic int pick_plru_victim(input logic [TREE_BITS-1:0] bits);
        int node = 0;              // heap index (0..TREE_BITS-1)
        int way  = 0;              // computed leaf index
        for (int lvl = 0; lvl < DEPTH; lvl++) begin
            logic dir = bits[node]; // 0 -> left (LRU), 1 -> right (LRU)
            if (dir) begin
                // go right half
                way  |= (1 << (DEPTH-1-lvl));
                node  = 2*node + 2;
            end else begin
                // go left half
                node  = 2*node + 1;
            end
        end
        return way;
    endfunction

    // Update PLRU bits along path to accessed way.
    // For each traversed node: set bit to the OPPOSITE of the taken branch (mark sibling as LRU)
    function automatic logic [TREE_BITS-1:0] plru_after_access(
        input logic [TREE_BITS-1:0] bits_in,
        input int                   way
    );
        logic [TREE_BITS-1:0] bits = bits_in;
        int node = 0;
        for (int lvl = 0; lvl < DEPTH; lvl++) begin
            int   shift = DEPTH-1-lvl;
            logic dir   = (way >> shift) & 1'b1; // 0 = left, 1 = right
            bits[node]  = ~dir;                  // mark sibling subtree as LRU
            node        = dir ? (2*node + 2) : (2*node + 1);
        end
        return bits;
    endfunction

    // ------------------------------ Main control ------------------------------
    int accessed_way;

    always_ff @(posedge clk) begin
        data_out         <= '0;
        dirty_block_out  <= '0;
        accessed_way     <= -1; // -1 means no access this cycle

        if (!hit) begin
            // MISS path
            int inv;
            inv = first_invalid_way();

            if (inv != -1) begin
                // Fill into an invalid way when refill handshake is asserted
                if (read_en_mem && write_en_cache) begin
                    cache[index][inv][0] <= 1;                             // valid
                    cache[index][inv][1] <= 0;                             // clean
                    cache[index][inv][TAG_WIDTH+1:2] <= tag;               // tag
                    cache[index][inv][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem; // block
                    accessed_way <= inv; // mark MRU
                end
            end else begin
                // All valid: choose victim from PLRU
                int vic;
                vic = pick_plru_victim(plru[index]);

                if (!info[vic].dirty) begin
                    if (read_en_mem && write_en_cache) begin
                        cache[index][vic][0] <= 1; // valid
                        cache[index][vic][1] <= 0; // clean
                        cache[index][vic][TAG_WIDTH+1:2] <= tag;
                        cache[index][vic][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                        accessed_way <= vic; // MRU after refill
                    end
                end else begin
                    // Dirty victim -> writeback when requested
                    if (read_en_cache && write_en_mem) begin
                        dirty_block_out <= info[vic].block;
                        cache[index][vic][1] <= 0; // clear dirty after handing off block
                    end
                end
            end

        end else begin
            // HIT path
            if (req_type && write_en_cache) begin
                // Write hit: update word, set dirty, update MRU
                for (int i = 0; i < NUM_WAYS; i++) begin
                    if (info[i].hit) begin
                        
                        cache[index][i][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
                        cache[index][i][1] <= 1; // dirty
                        accessed_way <= i;
                    end
                end
            end else if (!req_type && read_en_cache) begin
                // Read hit: output word, update MRU
                for (int i = 0; i < NUM_WAYS; i++) begin
                    if (info[i].hit) begin
                        data_out <= info[i].block[blk_offset*WORD_SIZE +: WORD_SIZE];
                        accessed_way <= i;
                    end
                end
            end
        end

        // Update PLRU tree bits if there was an access/refill that picks a way
        if (accessed_way >= 0) begin
            plru[index] <= plru_after_access(plru[index], accessed_way);
        end
    end


endmodule
