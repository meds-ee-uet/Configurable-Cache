// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
// Author: Ammarah Wakeel, Ayesha Anwar, Eman Nasar.
// Date: 15th, july, 2025.

//==============================================================
//  Module: cache_decoder
//  Description: Decodes a 32-bit memory address into tag, index, 
//            and block offset fields for a 2-way set associative cache.
//==============================================================

module cache_decoder(
    input  logic clk,            // Clock (not used in this decoder, 
                                 // but kept for synchronous design compatibility)
    input  logic [31:0] addr,    // 32-bit memory address input
    output logic [24:0] tag,     // Tag bits (upper address bits for cache lookup)
    output logic [4:0]  index,   // Index bits (selects cache set)
    output logic [1:0]  blk_offset // Block offset (word offset within a cache block)
);

    // Extract tag: upper 25 bits [31:7]
    // Tag is used to uniquely identify a block within the indexed set.
    assign tag = addr[31:7];

    // Extract index: middle 5 bits [6:2]
    // Index selects one of the cache sets (2^5 = 32 sets).
    assign index = addr[6:2];

    // Extract block offset: lower 2 bits [1:0]
    // Block offset selects the word within a cache block (assuming 4 words per block).
    assign blk_offset = addr[1:0];    

endmodule
