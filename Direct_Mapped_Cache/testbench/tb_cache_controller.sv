// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
//Description : this file contains the test code for  RTL of cache controller module of direct mapped cache..
// Author:  Ammarah Wakeel.
// Date: 10th, july, 2025.
// CACHE CONTROLLER IS SAME AS DIRECT MAPPED CACHE, 2 WAY CACHE AND N WAY CACHE
`timescale 1ns/1ps

module tb_cache_controller_all_cases;

    // DUT Inputs
    reg clk, rst;
    reg req_valid, req_type, hit, dirty_bit;

    // Handshake signals
    reg ready_mem;
    wire valid_cache;
    reg valid_mem;
    wire ready_cache;

    // DUT Outputs
    wire read_en_mem, write_en_mem, write_en, read_en_cache, write_en_cache, refill, done_cache;

    // Instantiate DUT
    cache_controller dut (
        .clk(clk),
        .rst(rst),
        .req_valid(req_valid),
        .req_type(req_type),
        .hit(hit),
        .dirty_bit(dirty_bit),
        .ready_mem(ready_mem),
        .valid_cache(valid_cache),
        .valid_mem(valid_mem),
        .ready_cache(ready_cache),
        .read_en_mem(read_en_mem),
        .write_en_mem(write_en_mem),
        .write_en(write_en),
        .read_en_cache(read_en_cache),
        .write_en_cache(write_en_cache),
        .refill(refill),
        .done_cache(done_cache)
    );

    // Clock generation (10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Function to get readable state names
  function string state_name(input [2:0] state);
        case (state)
            0: state_name = "IDLE";
            1: state_name = "COMPARE";
            2: state_name = "WRITE_BACK";
            3: state_name = "WRITE_ALLOCATE";
            4: state_name = "REFILL_DONE";
            default: state_name = "UNKNOWN";
        endcase
    endfunction

    //  Unified Display Task
    task print_state(input string test_name);
        $display("[%s] [TIME %0t] STATE=%s", test_name, $time, state_name(dut.current_state));
        $display("Inputs: req_valid=%0b, req_type=%0b, hit=%0b, dirty_bit=%0b",
                  req_valid, req_type, hit, dirty_bit);
      $display("Handshake: valid_cache=%0b, ready_mem=%0b, valid_mem=%0b, ready_cache=%0b",
                  valid_cache, ready_mem, valid_mem, ready_cache);
        $display("Outputs: read_mem=%0b, write_mem=%0b, read_cache=%0b, write_cache=%0b, refill=%0b, done=%0b\n",
                  read_en_mem, write_en_mem, read_en_cache, write_en_cache, refill, done_cache);
    endtask

    // VCD dump (for waveform if needed)
    initial begin
        $dumpfile("all_cases.vcd");
        $dumpvars(0, tb_cache_controller_all_cases);
    end

    // ---------- INDIVIDUAL TEST TASKS (ALL STATES PRINTED) ----------

    task run_read_hit();
        $display("\n=============== ✅ TEST: READ HIT ===============");
        req_valid=1;req_type=0; hit=1; dirty_bit=0;
	@(posedge clk)
	req_valid=0;
        @(posedge clk) print_state("READ HIT");
        req_valid=0; hit=0;
        @(posedge clk) print_state("READ HIT");
        wait(dut.current_state==0);
    endtask

    task run_write_hit();
        $display("\n===============  TEST: WRITE HIT ===============");
        req_valid=1; req_type=1; hit=1; dirty_bit=0;
        @(posedge clk)
	req_valid=0;
        @(posedge clk) print_state("WRITE HIT");
        req_valid=0; hit=0;
        @(posedge clk) print_state("WRITE HIT");
         wait(dut.current_state==0);
    endtask

    task run_read_miss_clean();
        $display("\n===============  TEST: READ MISS CLEAN ===============");
        req_valid=1; req_type=0; hit=0; dirty_bit=0;
        @(posedge clk)
	req_valid=0;
        @(posedge clk) print_state("READ MISS CLEAN");   // COMPARE
        @(posedge clk) print_state("READ MISS CLEAN");   // WRITE_ALLOCATE
        @(posedge clk) print_state("READ MISS CLEAN");
        valid_mem=1;ready_mem=0; @(posedge clk) print_state("READ MISS CLEAN"); // REFILL_DONE
        valid_mem=0;
        ready_mem=1;
        req_valid=0;
        @(posedge clk) print_state("READ MISS CLEAN");   // IDLE
        wait(dut.current_state==0);
    endtask

    task run_read_miss_dirty();
        $display("\n=============== TEST: READ MISS DIRTY ===============");
        req_valid=1; req_type=0; hit=0; dirty_bit=1;
        @(posedge clk)
	req_valid=0;
        @(posedge clk) print_state("READ MISS DIRTY");  // COMPARE
        @(posedge clk) print_state("READ MISS DIRTY");  // WRITE_BACK
        @(posedge clk) print_state("READ MISS DIRTY");
        @(posedge clk) print_state("READ MISS DIRTY");  // WAIT_ALLOCATE
        @(posedge clk) print_state("READ MISS DIRTY");  // WRITE_ALLOCATE
        @(posedge clk) print_state("READ MISS DIRTY");
        valid_mem=1;ready_mem=0; @(posedge clk) print_state("READ MISS DIRTY"); // REFILL_DONE
        valid_mem=0;
        ready_mem=1;
        req_valid=0;
        @(posedge clk) print_state("READ MISS DIRTY");  // IDLE
        wait(dut.current_state==0);
    endtask

    task run_write_miss_clean();
        $display("\n===============  TEST: WRITE MISS CLEAN ===============");
        req_valid=1; req_type=1; hit=0; dirty_bit=0;
        @(posedge clk)
	req_valid=0;
        @(posedge clk) print_state("WRITE MISS CLEAN"); // COMPARE
        @(posedge clk) print_state("WRITE MISS CLEAN"); // WRITE_ALLOCATE
        @(posedge clk) print_state("WRITE MISS CLEAN");
        valid_mem=1; ready_mem=0;  @(posedge clk) print_state("WRITE MISS CLEAN"); // REFILL_DONE
        valid_mem=0;
        ready_mem=1;
        req_valid=0;
        @(posedge clk) print_state("WRITE MISS CLEAN"); // IDLE
        wait(dut.current_state==0);
    endtask

    task run_write_miss_dirty();
        $display("\n===============  TEST: WRITE MISS DIRTY ===============");
        req_valid=1; req_type=1; hit=0; dirty_bit=1;
        @(posedge clk)
	req_valid=0;
        @(posedge clk) print_state("WRITE MISS DIRTY"); // COMPARE
        @(posedge clk) print_state("WRITE MISS DIRTY"); // WRITE_BACK
        @(posedge clk) print_state("WRITE MISS DIRTY");
        @(posedge clk) print_state("WRITE MISS DIRTY"); // WAIT_ALLOCATE
        @(posedge clk) print_state("WRITE MISS DIRTY"); // WRITE_ALLOCATE
        @(posedge clk) print_state("WRITE MISS DIRTY");
        valid_mem=1;ready_mem=0;  @(posedge clk) print_state("WRITE MISS DIRTY"); // REFILL_DONE
        valid_mem=0;
        ready_mem=1;
        req_valid=0;
        @(posedge clk) print_state("WRITE MISS DIRTY"); // IDLE
        wait(dut.current_state==0);
    endtask

    // ---------- MAIN TEST SEQUENCE ----------
    initial begin
        // Init
        rst=1; req_valid=0; req_type=0; hit=0; dirty_bit=0;
        @(posedge clk)
	    req_valid=0;
        ready_mem=1; valid_mem=0;
        #12 rst=0; @(posedge clk);

        run_read_hit();
        run_write_hit();
        run_read_miss_clean();
        run_read_miss_dirty();
        run_write_miss_clean();
        run_write_miss_dirty();

        $display("\n???  ALL 6 TEST CASES COMPLETED SUCCESSFULLY ???");
        $finish;
    end

endmodule

