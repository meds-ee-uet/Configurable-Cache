// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
//Description : this file contains top module for integrating all modules of direct mapped cache.
// Author:  Ammarah Wakeel, Ayesha Anwar, Eman Nasar.
// Date: 28th, june, 2025.
// CACHE CONTROLLER IS SAME AS DIRECT MAPPED CACHE, 2 WAY CACHE AND N WAY CACHE
module top (
    input  logic clk,
    input  logic rst,

    // From CPU
    input  logic        req_valid,
    input  logic        req_type,        // 0 = Read, 1 = Write
    input  logic [31:0] data_in,
    input logic [31:0] address,
    // To CPU
    output logic [31:0] data_out,
    output logic        done_cache
);
    // Decoder outputs
    logic [23:0] tag;
    logic [5:0] index;
    logic [1:0] blk_offset;
    //Cache_mem signals I/O
    logic  refill, read_en_cache, write_en_cache,[`BLOCK_SIZE-1:0] dirty_block_out, dirty_bit,hit;
    //Mem signals
    logic read_en_mem, write_en_mem, [`BLOCK_SIZE-1:0] data_out_mem, ready_mem, [`BLOCK_SIZE-1:0] dirty_block_in;

    //Instantiation
    cache_decoder decoder (
    .tag(tag),
    .index(index),
    .blk_offset(blk_offset)
    );
    cache_controller controller (
    .clk(clk),
    .rst(rst),
    .req_valid(req_valid),
    .req_type(req_type),
    .hit(hit),
    .dirty_bit(dirty_bit),
    .req_ready_mem(req_ready_mem),
    .req_valid_mem(req_valid_mem),
    .resp_valid_mem(resp_valid_mem),
    .resp_ready_mem(resp_ready_mem),
    .read_en_mem(read_en_mem),
    .write_en_mem(write_en_mem),
    .write_en(write_en),
    .read_en_cache(read_en_cache),
    .write_en_cache(write_en_cache),
    .refill(refill),
    .done_cache(done_cache)
);

    cache_memory cache (
    .clk(clk),
    .tag(tag),
    .index(index),
    .blk_offset(blk_offset),
    .req_type(req_type),
    .read_en_cache(read_en_cache),
    .write_en_cache(write_en_cache),
    .refill(refill),
    .data_in_mem(data_out_mem),         // From main memory
    .data_in(data_in),       // Word from CPU
    .dirty_block_out(dirty_block_out), // To memory
    .hit(hit),
    .data_out(data_out),
    .dirty_bit(dirty_bit),                // You'll need to expose this from cache
    .done_cache(done_cache)                
   );
  
endmodule

