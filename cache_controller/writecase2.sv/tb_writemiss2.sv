module tb_cache_controller_write_miss_clean;

    // Declare signals to connect to the UUT (Unit Under Test)
    logic clk, rst;
    logic req_valid, req_type, hit, dirty_bit, ready_mem;
    logic read_en_mem, write_en_mem, write_en, read_en_cache, write_en_cache, refill, done_cache;

    // Re-declare state_t enum (must match RTL!)
    typedef enum logic [3:0] {
        IDLE,           
        COMPARE,        
        WRITE_BACK,     
        WRITE_ALLOCATE, 
        REFILL_DONE     
    } state_t;

    // Instantiate the cache_controller module
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

    // Clock generation
    always #5 clk = ~clk;

    // ✅ Local function to convert state to string
    function string stateToString(input state_t state);
        case (state)
            IDLE:           return "IDLE";
            COMPARE:        return "COMPARE";
            WRITE_BACK:     return "WRITE_BACK";
            WRITE_ALLOCATE: return "WRITE_ALLOCATE";
            REFILL_DONE:    return "REFILL_DONE";
            default:        return "UNKNOWN";
        endcase
    endfunction

    // Helper task to check a specific signal's value against an expected value
    task check_signal(string name, logic signal, logic expected);
        if (signal !== expected)
            $display("❌ ERROR: %s: Expected = %0d, Got = %0d", name, expected, signal);
        else
            $display("✅ CHECK: %s OK (Value = %0d)", name, signal);
    endtask

    // Task to print the current state and all input/output signal values
    task print_state;
        $display("----------------------------------------");
        $display("[TIME %0t] Current State: %s", $time, stateToString(uut.current_state));
        $display("Inputs: req_valid=%b, req_type=%b, hit=%b, dirty_bit=%b, ready_mem=%b",
                 req_valid, req_type, hit, dirty_bit, ready_mem);
        $display("Outputs: read_mem=%b, write_mem=%b, write=%b, read_cache=%b, write_cache=%b, refill=%b, done=%b",
                 read_en_mem, write_en_mem, write_en, read_en_cache, write_en_cache, refill, done_cache);
    endtask

    // ✅ Test stimulus generation (Write Miss with Clean Block)
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
        print_state();
        check_signal("current_state", uut.current_state, IDLE);

        // Cycle 1: Write miss, clean block (start memory read)
        req_valid = 1;
        req_type = 1;   // ✅ Write request
        dirty_bit = 0;
        #10;
        print_state();
        check_signal("read_en_mem", read_en_mem, 1);

        // ✅ FIXED: Cycle 2: Memory not ready yet (still waiting)
        ready_mem = 0;
        #10;
        print_state();
        check_signal("read_en_mem", read_en_mem, 1); // ✅ Was 0 before, now 1

        // Cycle 3: Memory ready, refill cache
        ready_mem = 1;
        #10;
        print_state();
        check_signal("write_en_cache", write_en_cache, 1);
        check_signal("refill", refill, 0);

        // Cycle 4: Refill complete
        #10;
        print_state();
        check_signal("refill", refill, 1);

        // Cycle 5: Hit after refill → must now write to cache
        hit = 1;
        #10;
        print_state();
        check_signal("write_en_cache", write_en_cache, 1); // ✅ Write into cache
        check_signal("done_cache", done_cache, 1);

        // Cycle 6: Back to IDLE
        #10;
        print_state();
        check_signal("current_state", uut.current_state, IDLE);

        $display("✅ TEST COMPLETED SUCCESSFULLY for Write Miss with Clean Block.");
        $finish;
    end

endmodule
