module cache_controller (
    input  logic clk,         // Clock signal
    input  logic rst,         // Asynchronous reset

    // CPU-side interface
    input  logic req_valid,   // Request valid from CPU
    input  logic req_type,    // 0 = read, 1 = write
    input  logic hit,         // Cache hit signal
    input  logic dirty_bit,   // Dirty bit of the block to be evicted

    // Main memory handshake interface
    input  logic req_ready_mem,    // Memory ready to accept request
    output logic req_valid_mem,    // Cache has a valid request for memory
    input  logic resp_valid_mem,   // Memory returning valid data
    output logic resp_ready_mem,   // Cache ready to accept response

    // Main memory controls
    output logic read_en_mem,      // Read enable for memory
    output logic write_en_mem,     // Write enable for memory

    // Cache control
    output logic write_en,         // (optional) write enable for CPU writes
    output logic read_en_cache,    // Enable cache read
    output logic write_en_cache,   // Enable cache write (refill or CPU write)
    output logic refill,           // Cache block refilled
    output logic done_cache        // Cache operation complete
);

    // FSM states
    typedef enum logic [3:0] {
        IDLE,
        COMPARE,
        WRITE_BACK,
        WAIT_ALLOCATE,   // ✅ NEW STATE to insert 1-cycle gap
        WRITE_ALLOCATE,
        REFILL_DONE
    } state_t;

    state_t current_state, next_state;

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Next-state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:
                if (req_valid)
                    next_state = COMPARE;

            COMPARE:
                if (hit)
                    next_state = IDLE;
                else if (!dirty_bit)
                    next_state = WRITE_ALLOCATE;
                else
                    next_state = WRITE_BACK;

            WRITE_BACK:
                if (req_ready_mem) 
                    next_state = WAIT_ALLOCATE;  // ✅ Now go to WAIT_ALLOCATE

            WAIT_ALLOCATE:
                next_state = WRITE_ALLOCATE;     // ✅ 1-cycle gap before issuing new request

            WRITE_ALLOCATE:
                if (resp_valid_mem)
                    next_state = REFILL_DONE;

            REFILL_DONE:
                next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end

    // Output logic
    always_comb begin
        // Default outputs
        read_en_mem     = 0;
        write_en_mem    = 0;
        write_en        = 0;
        read_en_cache   = 0;
        write_en_cache  = 0;
        refill          = 0;
        done_cache      = 0;
        req_valid_mem   = 0;
        resp_ready_mem  = 0;

        case (current_state)
            IDLE: begin
                // Nothing to do, wait for CPU request
            end

            COMPARE: begin
                if (hit) begin
                    done_cache     = 1;
                    write_en_cache = req_type;   // Write if CPU write request
                    read_en_cache  = ~req_type;  // Read if CPU read request
                end
            end

            WRITE_BACK: begin
                req_valid_mem = 1;     // Request to write dirty block
                if (req_ready_mem) begin
                    write_en_mem = 1;  // Perform write-back
                end
            end

            WAIT_ALLOCATE: begin
                // ✅ New state: 1-cycle gap, no request to memory
                req_valid_mem   = 0;
                read_en_mem     = 0;
                write_en_mem    = 0;
                resp_ready_mem  = 0;
            end

            WRITE_ALLOCATE: begin
                req_valid_mem  = 1;    // Request to read new block
                if (req_ready_mem) begin
                    read_en_mem = 1;   // Perform memory read
                end
                resp_ready_mem = 1;    // Cache ready to accept data
                if (resp_valid_mem) begin
                    write_en_cache = 1; // Write data into cache
                end
            end

            REFILL_DONE: begin
                refill      = 1;
                done_cache  = 1;
                if (req_type)
                    write_en_cache = 1;  // Perform CPU write after refill
                else
                    read_en_cache  = 1;  // CPU read after refill
            end
        endcase
    end

endmodule

