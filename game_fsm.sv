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

module game_fsm_tb;
    logic clk, reset, tick, start_pulse, collision;
    logic game_active, clear_game;
    logic [1:0] state;

    game_fsm dut (
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .start_pulse(start_pulse),
        .collision(collision),
        .game_active(game_active),
        .clear_game(clear_game),
        .state(state)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task do_tick;
        begin
            tick = 1;
            @(posedge clk);
            tick = 0;
            @(posedge clk);
        end
    endtask

    initial begin
        reset = 1;
        tick = 0;
        start_pulse = 0;
        collision = 0;
        repeat (2) @(posedge clk);
        reset = 0;

        // Start game
        start_pulse = 1;
        @(posedge clk);
        start_pulse = 0;
        @(posedge clk);

        if (state != 2'd1)
            $error("Expected PLAY state, got %0d", state);

        // Trigger collision
        collision = 1;
        @(posedge clk);
        collision = 0;
        @(posedge clk);

        if (state != 2'd2)
            $error("Expected HIT state, got %0d", state);

        // Advance HIT delay
        repeat (16) do_tick();

        if (state != 2'd3)
            $error("Expected GAME_OVER state, got %0d", state);

        // Restart
        start_pulse = 1;
        @(posedge clk);
        start_pulse = 0;
        @(posedge clk);

        if (state != 2'd0)
            $error("Expected IDLE state after restart, got %0d", state);

        $display("game_fsm_tb PASSED");
        $finish;
    end
endmodule