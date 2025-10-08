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
  parameter int NUM_WAYS          = 4,
  parameter int NUM_SETS          = NUM_BLOCKS / NUM_WAYS,
  parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8,
  parameter int INDEX_WIDTH       = $clog2(NUM_SETS),
  parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK),
  parameter int TAG_WIDTH         = 32 - (INDEX_WIDTH + OFFSET_WIDTH)
)(
  input  logic                          clk,
  input  logic [TAG_WIDTH-1:0]          tag,
  input  logic [INDEX_WIDTH-1:0]        index,
  input  logic [OFFSET_WIDTH-1:0]       blk_offset,
  input  logic                          req_type,        // 0 = Read, 1 = Write
  input  logic                          read_en_cache,
  input  logic                          write_en_cache,
  input  logic                          read_en_mem,
  input  logic                          write_en_mem,
  input  logic [BLOCK_SIZE-1:0]         data_in_mem,
  input  logic [WORD_SIZE-1:0]          data_in,
  output logic [BLOCK_SIZE-1:0]         dirty_block_out,
  output logic                          hit,
  output logic [WORD_SIZE-1:0]          data_out,
  output logic                          dirty_bit
);

  localparam int DEPTH = (NUM_WAYS > 1) ? $clog2(NUM_WAYS) : 1;
  localparam int TREE_BITS = NUM_WAYS - 1;

  initial begin
    if (NUM_WAYS < 2 || (NUM_WAYS & (NUM_WAYS - 1)) != 0) begin
      $error("NUM_WAYS (%0d) must be a power of two and >= 2", NUM_WAYS);
    end
  end

  typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;
  cache_line_t cache [NUM_SETS-1:0][NUM_WAYS-1:0];

  logic [TREE_BITS-1:0] plru [NUM_SETS-1:0];

  typedef struct packed {
    logic valid;
    logic dirty;
    logic [TAG_WIDTH-1:0] tag;
    logic [BLOCK_SIZE-1:0] block;
    logic hit;
  } cache_info_t;

  cache_info_t info [NUM_WAYS-1:0];

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

  

  logic hit_comb;
  always_comb begin
    hit_comb = 1'b0;
    for (int i = 0; i < NUM_WAYS; i++) begin
      if (info[i].hit) hit_comb = 1'b1;
    end
  end
  assign hit = hit_comb;

  // Dirty if the selected victim is dirty
  logic [$clog2(NUM_WAYS)-1:0] victim_way;
  assign dirty_bit = info[victim_way].dirty && info[victim_way].valid;

  // ----------------- Invalid Way Search -----------------
  logic [$clog2(NUM_WAYS)-1:0] invalid_way;
  logic invalid_found;
  always_comb begin
    invalid_found = 1'b0;
    invalid_way = '0;
    for (int i = 0; i < NUM_WAYS; i++) begin
      if (!info[i].valid && !invalid_found) begin
        invalid_way = i;
        invalid_found = 1'b1;
      end
    end
  end

  // ----------------- PLRU Victim Way -----------------
  always_comb begin
    automatic int node;   // ✅ fixed
    int lvl;              // ✅ fixed
    logic dir;
    victim_way = '0;
    node = 0;
    for (lvl = 0; lvl < DEPTH; lvl++) begin
      dir = plru[index][node];
      if (dir) begin
        victim_way |= (1 << (DEPTH-1-lvl));
        node = 2*node + 2;
      end else begin
        node = 2*node + 1;
      end
    end
  end

  // ----------------- PLRU Update Logic -----------------
  logic [$clog2(NUM_WAYS)-1:0] accessed_way;
  logic accessed_valid;
  logic [TREE_BITS-1:0] plru_next;

  always_comb begin
    automatic int node;   // declare first
    int lvl;
    logic dir;

    plru_next = plru[index];  // statements after declarations
    node = 0;
    for (lvl = 0; lvl < DEPTH; lvl++) begin
      dir = accessed_way[DEPTH-1-lvl];
      plru_next[node] = ~dir;
      node = dir ? (2*node + 2) : (2*node + 1);
    end
end


  // ----------------- Refill Tracking -----------------
  logic writeback_pending;                       // ✅ moved up before use
  logic [$clog2(NUM_WAYS)-1:0] pending_victim_way;

  // ----------------- Main Control -----------------
  always_ff @(posedge clk) begin
    data_out <= '0;
    dirty_block_out <= '0;
    accessed_valid <= 1'b0;
    accessed_way <= '0;

    // Handle post-writeback refill
    if (writeback_pending && read_en_mem && write_en_cache) begin
      cache[index][pending_victim_way][0] <= 1'b1;
      cache[index][pending_victim_way][1] <= 1'b0;
      cache[index][pending_victim_way][TAG_WIDTH+1:2] <= tag;
      cache[index][pending_victim_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;

      accessed_way <= pending_victim_way;
      accessed_valid <= 1'b1;
      writeback_pending <= 1'b0;
    end

    // Miss Handling
    else if (!hit) begin
      if (invalid_found) begin
        if (read_en_mem && write_en_cache) begin
          cache[index][invalid_way][0] <= 1'b1;
          cache[index][invalid_way][1] <= 1'b0;
          cache[index][invalid_way][TAG_WIDTH+1:2] <= tag;
          cache[index][invalid_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
          accessed_way <= invalid_way;
          accessed_valid <= 1'b1;
        end
      end else begin
        if (!info[victim_way].dirty) begin
          if (read_en_mem && write_en_cache) begin
            cache[index][victim_way][0] <= 1'b1;
            cache[index][victim_way][1] <= 1'b0;
            cache[index][victim_way][TAG_WIDTH+1:2] <= tag;
            cache[index][victim_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
            accessed_way <= victim_way;
            accessed_valid <= 1'b1;
          end
        end else begin
          if (read_en_cache && write_en_mem) begin
            dirty_block_out <= info[victim_way].block;
            cache[index][victim_way][1] <= 1'b0;
            writeback_pending <= 1'b1;
            pending_victim_way <= victim_way;
          end
        end
      end
    end

    // Hit Handling
    else begin
      if (req_type && write_en_cache) begin
        for (int i = 0; i < NUM_WAYS; i++) begin
          if (info[i].hit) begin
            cache[index][i][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
            cache[index][i][1] <= 1'b1;
            accessed_way <= i;
            accessed_valid <= 1'b1;
          end
        end
      end else if (!req_type && read_en_cache) begin
        for (int i = 0; i < NUM_WAYS; i++) begin
          if (info[i].hit) begin
            data_out <= info[i].block[blk_offset*WORD_SIZE +: WORD_SIZE];
            accessed_way <= i;
            accessed_valid <= 1'b1;
          end
        end
      end
    end

    // ✅ Apply PLRU update only if access occurred
    if (accessed_valid) begin
      plru[index] <= plru_next;
    end
  end

endmodule
