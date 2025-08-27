// CACHE CONTROLLER IS SAME AS DIRECT MAPPED CACHE, 2 WAY CACHE AND N WAY CACHE

module cache_controller (
    input  logic clk,         // Clock signal
    input  logic rst,         // Asynchronous reset signal
    input  logic req_valid,   // Request valid signal from CPU
    input  logic req_type,    // 0 = read request, 1 = write request
    input  logic hit,         // Cache hit signal from cache memory
    input  logic dirty_bit,   // Dirty bit of the cache block to be evicted

    // Memory handshake
    input  logic ready_mem,   // Main memory is ready to accept data (during write-back) or is busy (during refill)
    input  logic valid_mem,   // Memory is sending valid data to cache

    // Cache handshake
    output logic valid_cache,  // Cache is sending valid data to memory
    output logic ready_cache,  // Cache is ready to accept data from memory

    output logic read_en_mem,    // Enable read from main memory
    output logic write_en_mem,   // Enable write to main memory
    output logic read_en_cache,  // Enable read from cache
    output logic write_en_cache, // Enable write to cache memory
    output logic refill,         // Signal indicating cache block has been refilled from memory
    output logic done_cache      // Signal indicating cache operation is complete
);

    // FSM state encoding
    typedef enum logic [2:0] {
        IDLE,
        COMPARE,
        WRITE_BACK,
        WRITE_ALLOCATE,
        REFILL_DONE
    } state_t;

    state_t current_state, next_state;

    // Sequential state update
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // FSM next-state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:
                if     (req_valid)
                    next_state = COMPARE;

            COMPARE: begin
                if (hit)
                    next_state = IDLE;
                else if (!dirty_bit)
                    next_state = WRITE_ALLOCATE;
                else
                    next_state = WRITE_BACK;
            end

            WRITE_BACK:
                if (valid_cache && ready_mem)
                    next_state = WRITE_ALLOCATE;

            WRITE_ALLOCATE:
                if (valid_mem && ready_cache)
                    next_state = REFILL_DONE;

            REFILL_DONE:
                next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end

    // Output logic (Ready-Valid Handshake Semantics)
    always_comb begin
        // Defaults
        read_en_mem      = 0;
        write_en_mem     = 0;
        write_en         = 0;
        read_en_cache    = 0;
        write_en_cache   = 0;
        refill           = 0;
        done_cache       = 0;

        valid_cache      = 0; 
        ready_cache      = 1; // default: cache is idle, so ready to receive

        case (current_state)
            IDLE: begin
                // Do nothing
            end

            COMPARE: begin
                if (hit) begin
                    done_cache     = 1;
                    write_en_cache = req_type;
                    read_en_cache  = ~req_type;
                end else if (!dirty_bit) begin
                    read_en_mem = 1; // Request block from memory
                end else begin
                    read_en_cache = 1;
                    valid_cache = 1; // Cache wants to send data
                    ready_cache = 0; // Cache is busy sending
                end
            end

            WRITE_BACK: begin
                valid_cache = 1;
                ready_cache = 0; // Cache is busy transmitting
                read_en_cache = 1;
                if (ready_mem)
                    write_en_mem = 1;
            end

            WRITE_ALLOCATE: begin
                read_en_mem  = 1;  // Memory begins to send data
                ready_cache  = 1;  // Cache ready to receive
               
                 // IMPORTANT: During this phase, memory should be sending valid data,
                // so memory must drive ready_mem = 0 (busy sending)

                if (valid_mem && ready_cache)
                    write_en_cache = 1;
            end

            REFILL_DONE: begin
                refill = 1;
                done_cache = 1;
                if (req_type)
                    write_en_cache = 1;
                else
                    read_en_cache = 1;
            end

            default: ;
        endcase
    end

endmodule
