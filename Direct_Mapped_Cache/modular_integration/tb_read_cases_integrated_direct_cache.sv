// Code your testbench here
`timescale 1ns/1ps

module tb_top;
    parameter int WORD_SIZE         = 32; 
    parameter int WORDS_PER_BLOCK   = 4;  
    parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE;
    parameter int NUM_BLOCKS        = 64; 
    parameter int TAG_WIDTH         = 24;
    parameter int INDEX_WIDTH       = $clog2(NUM_BLOCKS);
    parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK);

    // Clock and reset
    logic clk;
    logic rst;
   
    // CPU request signals
    logic req_valid;
    logic req_type; 
    logic [31:0] data_in;
    logic [31:0] address;

    // Outputs from DUT
    logic [31:0] data_out;
    logic        done_cache;

    // Memory handshake
    logic        ready_mem;
    logic        valid_mem;
    logic [BLOCK_SIZE-1:0] data_out_mem;

    // Instantiate DUT
    top dut (
        .clk(clk),
        .rst(rst),
        .req_valid(req_valid),
        .req_type(req_type),
        .data_in(data_in),
        .address(address),
        .data_out(data_out),
        .done_cache(done_cache),
        .ready_mem(ready_mem),
        .valid_mem(valid_mem),
        .data_out_mem(data_out_mem)
    );


    // Clock generation
    always #5 clk = ~clk;
    initial begin
     // Index 0
dut.cache.cache[0] = {
    128'hDEADBEEF_55667788_11223344_AABBCCDD,
    24'h1ABCDE, 1'b0, 1'b1
};

// Index 1
dut.cache.cache[1] = {
    128'hDAADBEEF_65667788_21223344_BABBCDDD,
    24'h1CBBDE, 1'b0, 1'b1
};

      // Index 2
dut.cache.cache[2] = {
    128'hFEEDFACE_77665544_33445566_CCDDEEFF,
    24'h1DCCEF, 1'b1, 1'b1
};

// Index 3
dut.cache.cache[3] = {
    128'hCAFEBABE_8899AABB_44556677_DDEEFF00,
    24'h1EDDEF, 1'b0, 1'b1
};

    end
    initial begin
        // Init
         clk = 0;
        rst = 1;
        req_valid = 0;
        req_type  = 0;
        data_in   = 0;
        address   = 0;
        ready_mem = 0;
        valid_mem = 0;
        data_out_mem = 0;
      
        // Release reset
       @(posedge clk);
       address = {24'h1ABCDE, 6'h0, 2'h3};
       req_type = 0;  
       req_valid=1;
       rst=0;
       @(posedge clk);
       @(posedge clk);      
       req_valid=0;
       
      $display("-----------------------------------------------------");
      $display("=== READ HIT TEST (way 0)===");
      $display("addr_in=%h tag_in_decoder=%h index=%h block offset=%h ",dut.u_decoder.address,dut.u_decoder.tag,dut.u_decoder.index,dut.u_decoder.blk_offset,);
      $display("Stored Tag: %h", dut.cache.stored_tag);

      $display("HIT: %h", dut.cache.hit);
      $display("Request type: %b", dut.controller.req_type);
      $display("Controller_hit: %0b", dut.controller.hit);
     
      $display("Read_en_cache: %0b", dut.controller.read_en_cache);
      @(posedge clk);
      $display("DATA_OUT: %h", data_out);
      $display("-----------------------------------------------------");
     
       // READ MISS (clean block replacement)
        $display("-----------------------------------------------------");
        $display("=== READ MISS TEST (CLEAN BLOCK) ===");

        // Request an address not matching cache TAG -> miss
        address   = 32'h0D5E6F02;
        req_type  = 0;   // read
        req_valid = 1;
        @(posedge clk);
        req_valid = 0;
        $display("addr_in=%h tag_in_decoder=%h index=%h block offset=%h",dut.u_decoder.address,dut.u_decoder.tag,dut.u_decoder.index,dut.u_decoder.blk_offset);
      
      $display("stored_tag: %h", dut.cache.stored_tag);
      $display("HIT: %h", dut.cache.hit);
      $display("Request type: %b", dut.controller.req_type);
      $display("Controller_hit: %0b", dut.controller.hit);
      
      $display("Ready_en_cache: %0b", dut.controller.read_en_cache);
      $display("Cache line before refill (Data Block only): %h", 
          dut.cache.cache[dut.u_decoder.index][153:26]);
      @(posedge clk);
      $display("DATA_OUT: %h", data_out);
      
    $display("-----------------------------------------------------");      
     
        // Memory responds
        repeat(2) @(posedge clk);
        valid_mem    = 1;
        ready_mem = 0;

        data_out_mem = 128'hDAAABEEF_55667788_11223344_AABBCCDD;
        $display("Current_State:",dut.controller.current_state);
        $display("Next:",dut.controller.next_state);
      
      @(posedge clk);
      
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
        
        @(posedge clk);
    $display("Cache line after refill (Data Block only): %h", 
          dut.cache.cache[dut.u_decoder.index][153:26]);

$display("Expected Data Block: %h", data_out_mem);

        ready_mem = 1;
  
    $display("-----------------------------------------------------");      
     
        // Wait for controller to finish
      wait(done_cache & dut.controller.read_en_cache);
      
      $display("Current_State:",dut.controller.current_state);
        $display("Next:",dut.controller.next_state);
        @(posedge clk);

        $display("addr_in=%h tag=%h index=%h offset=%h",
                  dut.u_decoder.address,
                  dut.u_decoder.tag,
                  dut.u_decoder.index,
                  dut.u_decoder.blk_offset);
       
      $display("stored_tag: %h", dut.cache.stored_tag);
        $display("Hit signal: %0b", dut.controller.hit);
      //$display("Read_en_cache: %b", dut.controller.read_en_cache);
        $display("Cache line after refill: %h",
                  dut.cache.cache[dut.u_decoder.index][153:26]);
        $display("DATA_OUT (word): %h", data_out);
      $display("READ MISS CLEAN CASE COMPLETED");   
        $display("-----------------------------------------------------");
         
    $display("-----------------------------------------------------");
      
      // READ MISS (dirty block replacement)
        $display("-----------------------------------------------------");
        $display("=== READ MISS TEST (DIRTY BLOCK) ===");

        // Request an address not matching cache TAG -> miss
        address   = 32'h2AAAAA08;
      valid_mem = 0;
      ready_mem = 0;

        req_type  = 0;   // read
        req_valid = 1;
        @(posedge clk);
        req_valid = 0;
        $display("addr_in=%h tag_in_decoder=%h index=%h block offset=%h",
                 dut.u_decoder.address,
                 dut.u_decoder.tag,
                 dut.u_decoder.index,
                 dut.u_decoder.blk_offset);
      
        $display("stored_tag: %h", dut.cache.stored_tag);
        $display("HIT: %h", dut.cache.hit);
        $display("Request type: %b", dut.controller.req_type);
        $display("Controller_hit: %0b", dut.controller.hit);
      
        $display("Read_en_cache: %0b", dut.controller.read_en_cache);
        $display("Cache line before eviction (Data Block only): %h", 
                 dut.cache.cache[dut.u_decoder.index][153:26]);

        // ---- Handle write-back for dirty miss ----
        wait(dut.controller.current_state == dut.controller.WRITE_BACK);
        $display("-----------------------------------------------------");
      
        $display("=== WRITE-BACK (Dirty Block Eviction) ===");
      $display("Current_State:",dut.controller.current_state);
        $display("Next:",dut.controller.next_state);
      
       $display("Evicted Data Block: %h", dut.cache.cache[dut.u_decoder.index][153:26]);
      
        $display("Evicted Tag       : %h", dut.cache.cache[dut.u_decoder.index][25:2]);

        ready_mem = 1;  // memory accepts dirty data
      $display("data_out_mem: %h", dut.cache.dirty_block_out);
      
        @(posedge clk);
        ready_mem = 0;

        // ---- Now memory sends new block (same as clean miss) ----
       $display("-----------------------------------------------------");
      $display("=== WRITE-Allocate (AFTER Dirty Block Eviction) ===");
        repeat(2) @(posedge clk);
        valid_mem    = 1;
        ready_mem    = 0;

        data_out_mem = 128'hDAAABEEF_55667788_11223344_AABBCCDD;
        $display("Current_State:",dut.controller.current_state);
        $display("Next:",dut.controller.next_state);
      
        @(posedge clk);
      
        $display("read_en_mem: %0b", dut.cache.read_en_mem);
        $display("write_en_cache: %0b", dut.cache.write_en_cache);
        
        @(posedge clk);
        $display("Cache line after refill (Data Block only): %h", 
                 dut.cache.cache[dut.u_decoder.index][153:26]);

        $display("Expected Data Block: %h", data_out_mem);

        ready_mem = 1;
        valid_mem = 0;
        $display("-----------------------------------------------------");      
     
        // Wait for controller to finish
        wait(done_cache & dut.controller.read_en_cache);
      
        $display("Current_State:",dut.controller.current_state);
        $display("Next:",dut.controller.next_state);
        @(posedge clk);

        $display("addr_in=%h tag=%h index=%h offset=%h",
                  dut.u_decoder.address,
                  dut.u_decoder.tag,
                  dut.u_decoder.index,
                  dut.u_decoder.blk_offset);
       
        $display("stored_tag: %h", dut.cache.stored_tag);
        $display("Hit signal: %0b", dut.controller.hit);
        $display("Cache line after refill: %h",
                  dut.cache.cache[dut.u_decoder.index][153:26]);
        $display("DATA_OUT (word): %h", data_out);
        $display("-----------------------------------------------------");

    
        $finish;
    end
endmodule