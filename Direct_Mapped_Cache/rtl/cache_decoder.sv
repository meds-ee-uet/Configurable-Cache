// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
//Description : this file contains RTL of cache decoder..
// Author:  Ammarah Wakeel,Ayesha Anwar, Eman Nasar. 
// Date: 28th, june, 2025.

// ============================================================================
// Module: cache_decoder
// Description: 
//   This module decodes a 32-bit memory address into three parts required
//   by a cache memory system: tag, index, and block offset.
// 
//   Address breakdown (32 bits):
//   -------------------------------------------------------------
//   |       TAG (24 bits)      |  INDEX (6 bits)  | OFFSET (2 bits) |
//   -------------------------------------------------------------
//   [31......................8][7..............2][1..............0]
// 
// Ports:
//   - clk       : Clock input (not used here, but included for synchronization)
//   - address   : 32-bit memory address to be decoded
//   - tag       : Extracted upper 24 bits of the address
//   - index     : Middle 6 bits, used to select cache set
//   - blk_offset: Lower 2 bits, used to select word within a cache block
// ============================================================================
module cache_decoder(clk, address, tag, index, blk_offset);
    input logic clk;
    input logic [31:0] address;
    output logic [23:0] tag;
    output logic [5:0] index;
    output logic [1:0] blk_offset;
    
    
    assign tag = address[31:8];
    assign index = address[7:2];
    assign blk_offset = address[1:0];
    

endmodule

