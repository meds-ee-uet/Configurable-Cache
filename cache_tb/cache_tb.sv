`timescale 1ns / 1ps

module cache_tb();

    // Clock and Reset
    logic clk;
    logic rst;

    // CPU-side inputs
    logic req_valid;
    logic req_type;      // 0 = Read, 1 = Write
    logic [31:0] data_in;
    logic [31:0] address;

    // CPU-side outputs
    logic [31:0] data_out;
    logic done_cache;

    // Memory interface signals (simulated in TB)
    logic read_en_mem, write_en_mem;
    
    logic [127:0] data_out_mem;
    logic [127:0] dirty_block_out;
    logic ready_mem;

    // Instantiate top
    cache_top dut (
        .clk(clk),
        .rst(rst),
        .req_valid(req_valid),
        .req_type(req_type),
        .data_in(data_in),
        .address(address),
        .data_out(data_out),
        .done_cache(done_cache),
        .read_en_mem(read_en_mem),
        .write_en_mem(write_en_mem),
        .dirty_block_out(dirty_block_out),
        .data_out_mem(data_out_mem),
        .ready_mem(ready_mem)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Simulated Memory Array
    logic [31:0] memory_array [0:255];
    initial begin
        for (int i = 0; i < 256; i++)
            memory_array[i] = i;
    end

    // Memory Behavior
    always_ff @(posedge clk) begin
        if (read_en_mem) begin
            ready_mem <= 1;
            for (int i = 0; i < 4; i++) begin
                data_out_mem[i*32 +: 32] <= memory_array[(address >> 2) + i];
            end
        end else begin
            ready_mem <= 0;
        end

        if (write_en_mem) begin
            $display("[MEM WRITE] Addr: %h, Data: %h", address, dirty_block_out);
        end
    end

    // Task to apply a CPU request
    task send_request(input [31:0] addr, input [31:0] wdata, input bit is_write);
        address    = addr;
        data_in    = wdata;
        req_type   = is_write;
        req_valid  = 1;
        wait (done_cache);
        @(posedge clk);
        req_valid = 0;
        @(posedge clk);
    endtask

    // Simulation
    initial begin
    $dumpfile("cache.vcd");
    $dumpvars(0, cache_tb); // Was `top_tb`, should be your module name

    clk = 0;
    rst = 1;
    req_valid = 0;
    // DO NOT set ready_mem here!
    @(posedge clk);
    rst = 0;
        

        // -------------------------------
        // 1. Write Miss (Clean Block)
        // -------------------------------
        send_request(32'h00000020, 32'hDEADBEEF, 1);

        // -------------------------------
        // 2. Read Miss (Clean Block)
        // -------------------------------
        send_request(32'h00000040, 32'h00000000, 0);

        // -------------------------------
        // 3. Write Miss (Dirty Block)
        // -------------------------------
        send_request(32'h00000060, 32'hAAAA_BBBB, 1);
        send_request(32'h00000080, 32'hBBBB_CCCC, 1); // evicts dirty block at 0x60

        // -------------------------------
        // 4. Read Miss (Dirty Block)
        // -------------------------------
        send_request(32'h000000A0, 32'hCCCC_DDDD, 1);
        send_request(32'h000000C0, 32'h00000000, 0); // evicts dirty block at 0xA0

        // -------------------------------
        // 5. Write Hit
        // -------------------------------
        send_request(32'h000000C0, 32'hEEEEFFFF, 1);

        // -------------------------------
        // 6. Read Hit
        // -------------------------------
        send_request(32'h000000C0, 32'h00000000, 0);

        $display("\nAll test cases complete.\n");
        #20;
        $finish;
    end

endmodule
