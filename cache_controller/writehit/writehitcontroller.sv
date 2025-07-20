module cache_controller (
    input  logic clk,         // Clock signal
    input  logic rst,         // Asynchronous reset signal
    input  logic req_valid,   // Request valid signal from CPU
    input  logic req_type,    // 0 = read request, 1 = write request
    input  logic hit,         // Cache hit signal from cache memory
    input  logic dirty_bit,   // Dirty bit of the cache block to be evicted
    input  logic ready_mem,   // Memory ready signal from main memory

    output logic read_en_mem,    // Enable read from main memory
    output logic write_en_mem,   // Enable write to main memory
    output logic write_en,       // General write enable (not used in this FSM, typically for cache data write)
    output logic read_en_cache,  // Enable read from cache (not used in this FSM, typically for cache data read)
    output logic write_en_cache, // Enable write to cache memory
    output logic refill,         // Signal indicating cache block has been refilled from memory
    output logic done_cache      // Signal indicating cache operation is complete
);

    // Define FSM states
    typedef enum logic [3:0] {
        IDLE,           // Waiting for a new request
        COMPARE,        // Comparing tag, checking hit/miss
        WRITE_BACK,     // Writing dirty block back to main memory
        WRITE_ALLOCATE, // Reading new block from main memory to refill cache
        REFILL_DONE     // New state: Indicates cache refill is complete and 'refill' signal is asserted
    } state_t;

    state_t current_state, next_state; // Current and next state registers

    // State Register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;      // Reset to IDLE state
        end else begin
            current_state <= next_state; // Move to the next state
        end
    end

    // Next State Logic
    always_comb begin
        next_state = current_state; // Default to staying in the current state
        case (current_state)
            IDLE:
                if (req_valid) next_state = COMPARE; // If request is valid, move to COMPARE

            COMPARE:
                if (hit) begin
                    next_state = IDLE; // If hit, operation complete, go back to IDLE
                end else if (!dirty_bit) begin
                    next_state = WRITE_ALLOCATE; // Clean miss, move to WRITE_ALLOCATE
                end else begin
                    next_state = WRITE_BACK; // Dirty block, write-back required
                end

            WRITE_BACK:
                    next_state = WRITE_ALLOCATE; // Memory write complete, now refill from memory

            WRITE_ALLOCATE:
                if (ready_mem)
                    next_state = REFILL_DONE; // Memory read complete, cache write initiated

            REFILL_DONE:
                next_state = COMPARE; // Refill signal asserted, now go back to COMPARE to re-evaluate (should be a hit)

            default:
                next_state = IDLE; // Fallback to IDLE for any undefined state
        endcase
    end

    // Output Logic
    always_comb begin
        // Default values for all outputs
        read_en_mem = 0;
        write_en_mem = 0;
        write_en = 0;
        read_en_cache = 0;
        write_en_cache = 0;
        refill = 0;
        done_cache = 0;

        case (current_state)
            IDLE: begin
                // No specific outputs in IDLE state
            end

            COMPARE: begin
                if (hit) begin
                    done_cache = 1; // Cache operation done on a hit
                    read_en_cache = ~req_type; // Enable cache read only for read requests
                end else begin
                    if (!dirty_bit) 
                        read_en_mem = 1; // Initiate memory read for clean block miss
                    else
                        write_en_mem = 1; // Initiate memory write for dirty block write-back
                end
            end

            WRITE_BACK: begin
                write_en_mem = 1; // Keep memory write enabled during write-back
            end

            WRITE_ALLOCATE: begin
                read_en_mem = 1;        // ✅ Start reading from main memory
                if (ready_mem) begin
                    write_en_cache = 1; // Enable write to cache when memory data is ready
                end
            end

            REFILL_DONE: begin
                refill = 1; // Assert refill signal for one cycle
            end

            default: ; // No specific outputs for default state
        endcase
    end

endmodule
