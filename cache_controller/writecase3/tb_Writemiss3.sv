// Code your testbench here
`timescale 1ns/1ps

module tb_cache_controller;

    // DUT Inputs
    reg clk;
    reg rst;
    reg req_valid;
    reg req_type;        // 0=read, 1=write
    reg hit;
    reg dirty_bit;
    reg ready_mem;

    // DUT Outputs
    wire read_en_mem;
    wire write_en_mem;
    wire write_en;       // ✅ Added (was missing before)
    wire read_en_cache;
    wire write_en_cache;
    wire refill;
    wire done_cache;

    // Instantiate DUT
    cache_controller dut (
        .clk(clk),
        .rst(rst),
        .req_valid(req_valid),
        .req_type(req_type),
        .hit(hit),
        .dirty_bit(dirty_bit),
        .ready_mem(ready_mem),
        .read_en_mem(read_en_mem),
        .write_en_mem(write_en_mem),
        .write_en(write_en),        // ✅ Connected now
        .read_en_cache(read_en_cache),
        .write_en_cache(write_en_cache),
        .refill(refill),
        .done_cache(done_cache)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Display internal state and outputs
    always @(posedge clk) begin
        $display("[TIME %0t] STATE=%0d | req_valid=%0b, req_type=%0b, hit=%0b, dirty_bit=%0b, ready_mem=%0b",
                 $time, dut.current_state, req_valid, req_type, hit, dirty_bit, ready_mem);
        $display("Outputs: read_en_mem=%0b, write_en_mem=%0b, write_en=%0b, write_en_cache=%0b, read_en_cache=%0b, refill=%0b, done_cache=%0b\n",
                 read_en_mem, write_en_mem, write_en, write_en_cache, read_en_cache, refill, done_cache);
    end

    // Stimulus sequence
    initial begin
        // Initial reset
        rst = 1;
        req_valid = 0;
        req_type = 0;
        hit = 0;
        dirty_bit = 0;
        ready_mem = 0;
        #12 rst = 0; // Deassert reset

        // === Test sequence matching golden expected behavior ===

        // [TIME ~15k] New request, miss, dirty=1
        #10 req_valid = 1; req_type = 1; hit = 0; dirty_bit = 1; ready_mem = 0;

        // [TIME ~25k] Controller goes to WRITE_BACK
        #10;

        // [TIME ~35k] Continue write-back
        #10;

        // [TIME ~45k] Finish write-back, ready_mem=0 (still fetching new block)
        #10 dirty_bit = 0;

        // [TIME ~55k] Memory ready now
        #10 ready_mem = 1;

        // [TIME ~65k] Cache refill done
        #10 ready_mem = 0; hit = 1;

        // [TIME ~75k] Cache hit on retry
        #10 req_valid = 0;

        #20 $finish;
    end

endmodule