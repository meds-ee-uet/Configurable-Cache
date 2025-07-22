`timescale 1ns/1ps

module cache_decoder_tb;

    // Testbench signals
    logic clk;
    logic [31:0] address;
    logic [23:0] tag;
    logic [5:0] index;
    logic [1:0] blk_offset;

    // Instantiate DUT
    cache_decoder uut (
        .clk(clk),
        .address(address),
        .tag(tag),
        .index(index),
        .blk_offset(blk_offset)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    initial begin
        // Initialize
        address = 32'b0;

        // Allow settling
        #12;

        // Provide address in binary:
        // Example address: 32'b11011110101011011011111011101111
        // Same as 0xDEADBEEF
        address = 32'b11011110101011011011111011101111;

        // Wait for next posedge clk
        @(posedge clk);

        // Display outputs for manual checking
        $display("Address = %b", address);
        $display("Tag     = %b", tag);
        $display("Index   = %b", index);
        $display("BlkOff  = %b", blk_offset);

        #10;
        $finish;
    end

endmodule
