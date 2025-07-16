module cache_controller (
    input  logic clk,
    input  logic rst,
    input  logic req_valid,
    input  logic req_type,          // 0 = Read, 1 = Write
    input  logic hit,
    input  logic dirty_bit,
    input  logic ready_mem,

    output logic read_en_mem,
    output logic write_en_mem,
    output logic write_en,
    output logic read_en_cache,
    output logic write_en_cache,
    output logic refill,
    output logic done_cache
);

    typedef enum logic [2:0] {
        IDLE,
        COMPARE,
        WRITE_BACK,
        WRITE_ALLOCATE
    } state_t;

    state_t current_state, next_state;

    // --------------------------
    // State register
    // --------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // --------------------------
    // Next-state logic
    // --------------------------
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (req_valid)
                    next_state = COMPARE;
            end
            COMPARE: begin
                if ((req_type ||!req_type) && hit)
                    next_state = IDLE;
                else if ((req_type ||!req_type)  && !hit && !dirty_bit)
                    next_state = WRITE_ALLOCATE;
                else if ((req_type ||!req_type)  && !hit && dirty_bit)
                    next_state = WRITE_BACK;                          
            end
            WRITE_BACK: begin
                next_state = WRITE_ALLOCATE;
            end
            WRITE_ALLOCATE: begin
                if (ready_mem)
                    next_state = COMPARE;
            end
            default: next_state = IDLE;
        endcase
    end

    // --------------------------
    // Output logic (Mealy)
    // --------------------------
    always_comb begin
        // Default values
        read_en_mem    = 0;
        write_en_mem   = 0;
        write_en       = 0;
        read_en_cache  = 0;
        write_en_cache = 0;
        refill         = 0;
        done_cache     = 0;

        case (current_state)
            COMPARE: begin
                if (req_type == 0 && hit) begin
                    read_en_cache = 1;
                    done_cache    = 1;
                end
                else if ((req_type || !req_type) && !hit && !dirty_bit) begin
                    read_en_mem = 1;
                end
                else if ((req_type || !req_type) && !hit && dirty_bit) begin
                    write_en_mem = 1;
                end
                else if (req_type == 1 && hit) begin
                    write_en_cache = 1;
                    done_cache     = 1;
                end
                
                
            end

            WRITE_BACK: begin
                read_en_mem = 1;
            end

            WRITE_ALLOCATE: begin
                if (ready_mem) begin
                    write_en_cache = 1;
                    refill          = 1;
                end
            end
        endcase
    end

endmodule