// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: This file contains the RTL code 2 way set associative cache memory module to synthesize and implement it in vivado
//
// Author: Ammarah Wakeel.
// Date: 20th, August, 2025.
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/18/2025 03:28:00 AM
// Design Name: 
// Module Name: cache_memory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module top_cache_controller #(
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
) (
    input  logic                     clk,
    input  logic                     rst,

    // ---- nibble entry interface ----
    input  logic [3:0]               sw_nibble,     // nibble from switches
    input  logic                     load_address,  // pulse to shift into address
    input  logic                     load_data,     // pulse to shift into data_in
    input  logic                     clear_address, // pulse to reset address
    input  logic                     clear_data,    // pulse to reset data_in

    // ---- cache control signals (1-bit like before) ----
    input  logic                     req_type,     
    input  logic                     read_en_cache,
    input  logic                     write_en_cache,
    input  logic                     read_en_mem,
    input  logic                     write_en_mem,
   // REMOVED: input  logic [BLOCK_SIZE-1:0]    data_in_mem,  // <-- now internal  
    input  logic                     refill,

    output logic [BLOCK_SIZE-1:0]    dirty_block_out,
    output logic                     hit,
    output logic [WORD_SIZE-1:0]     data_out,
    output logic                     dirty_bit
);

    // ---- 32-bit registers built nibble by nibble ----
    logic [31:0] address_reg, data_in_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            address_reg <= 32'b0;
            data_in_reg <= 32'b0;
        end else begin
            if (clear_address)
                address_reg <= 32'b0;
            else if (load_address)
                address_reg <= {address_reg[27:0], sw_nibble};

            if (clear_data)
                data_in_reg <= 32'b0;
            else if (load_data)
                data_in_reg <= {data_in_reg[27:0], sw_nibble};
        end
    end

    // Internal signals from decoder
    logic [TAG_WIDTH-1:0]     tag;
    logic [INDEX_WIDTH-1:0]   index;
    logic [OFFSET_WIDTH-1:0]  blk_offset;

    // ---- use built 32-bit address ----
    cache_decoder decoder_inst (
        .clk(clk),
        .address(address_reg),
        .tag(tag),
        .index(index),
        .blk_offset(blk_offset)
    );

// ---- on-chip memory stub wiring ----
    localparam int MEM_DEPTH       = 256;                         // small, on-chip
    localparam int MEM_ADDR_WIDTH  = $clog2(MEM_DEPTH);

    // use low bits of {tag,index} as memory address
    logic [MEM_ADDR_WIDTH-1:0] mem_addr;
    assign mem_addr = {tag, index}[MEM_ADDR_WIDTH-1:0];

    logic [BLOCK_SIZE-1:0] data_in_mem_i; // from stub to cache (refill)

    mem_stub #(
        .BLOCK_SIZE(BLOCK_SIZE),         // 128
        .MEM_DEPTH(MEM_DEPTH),
        .ASYNC_READ(1)                   // 1 = distributed RAM, zero-latency read
    ) u_mem (
        .clk(clk),
        .read_en_mem(read_en_mem),
        .write_en_mem(write_en_mem),
        .addr(mem_addr),
        .din(dirty_block_out),           // write-back from cache
        .dout(data_in_mem_i)             // refill to cache
    );
    
    // ---- pass built 32-bit data_in ----
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
    ) cache_mem_inst (
        .clk(clk),
        .tag(tag),
        .index(index),
        .blk_offset(blk_offset),
        .req_type(req_type),
        .read_en_cache(read_en_cache),
        .write_en_cache(write_en_cache),
        .read_en_mem(read_en_mem),
        .write_en_mem(write_en_mem),
        .data_in_mem(data_in_mem_i),
        .data_in(data_in_reg),   // <-- nibble-built 32-bit data
        .refill(refill),
        .dirty_block_out(dirty_block_out),
        .hit(hit),
        .data_out(data_out),
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
    input logic refill,
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
    assign dirty_bit = info0.dirty || info1.dirty;

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
                cache[index][1][1]  <= 0;
                cache[index][1][TAG_WIDTH+1:2] <= tag;
                cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                 plru[index] <= 0;

          end else if ( plru[index] == 0 && info0.dirty && read_en_cache && write_en_mem) begin
                dirty_block_out <= info0.block;
                cache[index][1][1] <= 0;

          end else if (plru[index] == 1 && info1.dirty && read_en_cache && write_en_mem) begin
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
            end else if (refill==1 && write_en_cache && plru[index]==1) begin
                cache[index][1][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
                cache[index][1][1] <= 1;
                plru[index] <= 0;
            end else if (refill==1 && write_en_cache && plru[index]==0) begin
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
          end else if (refill==1 && read_en_cache && plru[index]==1) begin
                data_out <= info0.block[blk_offset*WORD_SIZE +: WORD_SIZE];
                plru[index] <= 0;
          end else if (refill==1 && read_en_cache && plru[index]==0) begin
                data_out <= info1.block[blk_offset*WORD_SIZE +: WORD_SIZE];
                plru[index] <= 0;
            end
        end
    end
endmodule


// Simple on-chip memory to serve 128-bit blocks.
// Default: ASYNC_READ=1 ? zero-latency (distributed RAM), matches your cache timing.
// Set ASYNC_READ=0 ? 1-cycle latency (block RAM). Then adjust cache timing accordingly.
module mem_stub #(
    parameter int BLOCK_SIZE   = 128,
    parameter int MEM_DEPTH    = 256,
    parameter int ADDR_WIDTH   = $clog2(MEM_DEPTH),
    parameter bit ASYNC_READ   = 1     // 1: distributed (comb read), 0: BRAM (sync read)
)(
    input  logic                   clk,
    input  logic                   read_en_mem,
    input  logic                   write_en_mem,
    input  logic [ADDR_WIDTH-1:0]  addr,
    input  logic [BLOCK_SIZE-1:0]  din,   // write-back from cache
    output logic [BLOCK_SIZE-1:0]  dout   // refill to cache
);
    generate
        if (ASYNC_READ) begin : G_DIST
            // Distributed RAM (LUT), combinational read ? zero-cycle
            (* ram_style = "distributed" *) logic [BLOCK_SIZE-1:0] mem [0:MEM_DEPTH-1];

            // Optional init pattern for visibility
            initial begin : init_mem
                integer i;
                for (i = 0; i < MEM_DEPTH; i++) mem[i] = {4{32'hDEAD_0000 + i}};
            end

            always_ff @(posedge clk) begin
                if (write_en_mem) mem[addr] <= din;
            end
            assign dout = read_en_mem ? mem[addr] : '0;

        end else begin : G_BRAM
            // Block RAM (BRAM), synchronous read ? 1-cycle latency
            (* ram_style = "block" *) logic [BLOCK_SIZE-1:0] mem [0:MEM_DEPTH-1];

            initial begin : init_mem
                integer i;
                for (i = 0; i < MEM_DEPTH; i++) mem[i] = {4{32'hDEAD_0000 + i}};
            end

            always_ff @(posedge clk) begin
                if (write_en_mem) mem[addr] <= din;
                if (read_en_mem)  dout      <= mem[addr];
            end
        end
    endgenerate
endmodule

