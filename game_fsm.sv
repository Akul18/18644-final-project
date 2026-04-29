module game_fsm (
    input  logic       clk,
    input  logic       reset,
    input  logic       tick,
    input  logic       start_pulse,
    input  logic       collision,
    output logic       game_active,
    output logic       clear_game,
    output logic [1:0] state
);
    typedef enum logic [1:0] {
        IDLE      = 2'd0,
        PLAY      = 2'd1,
        HIT       = 2'd2,
        GAME_OVER = 2'd3
    } state_t;

    state_t curr, next;
    logic [5:0] delay_count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            curr <= IDLE;
        else
            curr <= next;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            delay_count <= 0;
        else if (tick) begin
            if (curr == HIT || curr == GAME_OVER)
                delay_count <= delay_count + 1'b1;
            else
                delay_count <= 0;
        end
    end

    always_comb begin
        next        = curr;
        game_active = 1'b0;
        clear_game  = 1'b0;

        case (curr)
            IDLE: begin
                clear_game = 1'b1;
                if (start_pulse)
                    next = PLAY;
            end

            PLAY: begin
                game_active = 1'b1;
                if (collision)
                    next = HIT;
            end

            HIT: begin
                if (delay_count == 6'd15)
                    next = GAME_OVER;
            end

            GAME_OVER: begin
                if (start_pulse)
                    next = IDLE;
            end
        endcase
    end

    assign state = curr;
endmodule
