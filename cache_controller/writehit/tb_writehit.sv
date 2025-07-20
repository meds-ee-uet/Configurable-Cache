module tb_cache_controller_write_hit;

    logic clk, rst;
    logic req_valid, req_type, hit, dirty_bit, ready_mem;
    logic read_en_mem, write_en_mem, write_en, read_en_cache, write_en_cache, refill, done_cache;

    // Instantiate the DUT
    cache_controller uut (
        .clk(clk),
        .rst(rst),
        .req_valid(req_valid),
        .req_type(req_type),
        .hit(hit),
        .dirty_bit(dirty_bit),
        .ready_mem(ready_mem),
        .read_en_mem(read_en_mem),
        .write_en_mem(write_en_mem),
        .write_en(write_en),
        .read_en_cache(read_en_cache),
        .write_en_cache(write_en_cache),
        .refill(refill),
        .done_cache(done_cache)
    );

    // Clock generation (period = 10)
    always #5 clk = ~clk;

    task print_state;
        $display("[TIME %0t] STATE=%0d | req_valid=%b, req_type=%b, hit=%b", 
                  $time, uut.current_state, req_valid, req_type, hit);
        $display("Outputs: write_en_cache=%b, done_cache=%b\n", 
                  write_en_cache, done_cache);
    endtask

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        req_valid = 0;
        req_type = 0;
        hit = 0;
        dirty_bit = 0;
        ready_mem = 0;

        // Reset
        #10 rst = 0;
        @(posedge clk);

        // ---------- Cycle 1: IDLE ----------
        print_state();

        // ---------- Cycle 2: Write Hit ----------
        req_valid = 1;
        req_type = 1;  // ✅ Write request
        hit = 1;       // ✅ Cache hit
        @(posedge clk);
        print_state();
        if (!(write_en_cache && done_cache))
            $display("❌ ERROR: Expected write_en_cache=1 and done_cache=1 on write hit!");

        // ---------- Cycle 3: Return to IDLE ----------
        @(posedge clk);
        req_valid = 0; // No new request
        hit = 0;
        print_state();

        $display("✅ TEST COMPLETED for Write Hit");
        $finish;
    end

endmodule
