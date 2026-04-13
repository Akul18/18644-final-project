module bird_physics #(
    parameter int SCREEN_H      = 480,
    parameter int GROUND_Y      = 430,
    parameter int BIRD_START_Y  = 200,
    parameter int GRAVITY       = 1,
    parameter int JUMP_IMPULSE  = -6
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        tick,
    input  logic        game_active,
    input  logic        flap_pulse,
    output logic signed [10:0] bird_y,
    output logic signed [10:0] bird_vy
);
    logic signed [10:0] next_vy, next_y;

    always_comb begin
        next_vy = bird_vy + GRAVITY;
        if (flap_pulse)
            next_vy = JUMP_IMPULSE;

        next_y = bird_y + next_vy;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            bird_y  <= BIRD_START_Y;
            bird_vy <= 0;
        end else if (!game_active) begin
            bird_y  <= BIRD_START_Y;
            bird_vy <= 0;
        end else if (tick) begin
            bird_y  <= next_y;
            bird_vy <= next_vy;
        end
    end
endmodule

module bird_physics_tb;
    logic clk, reset, tick, game_active, flap_pulse;
    logic signed [10:0] bird_y, bird_vy;

    bird_physics #(
        .BIRD_START_Y(200),
        .GRAVITY(1),
        .JUMP_IMPULSE(-6)
    ) dut (
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .game_active(game_active),
        .flap_pulse(flap_pulse),
        .bird_y(bird_y),
        .bird_vy(bird_vy)
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
        game_active = 0;
        flap_pulse = 0;
        repeat (2) @(posedge clk);
        reset = 0;

        // inactive => should stay reset/start values
        repeat (2) do_tick();
        if (bird_y !== 200 || bird_vy !== 0)
            $error("Bird changed while inactive");

        game_active = 1;

        // gravity tick 1
        do_tick();
        $display("After tick1: y=%0d vy=%0d", bird_y, bird_vy);

        // gravity tick 2
        do_tick();
        $display("After tick2: y=%0d vy=%0d", bird_y, bird_vy);

        // flap
        flap_pulse = 1;
        do_tick();
        flap_pulse = 0;
        $display("After flap: y=%0d vy=%0d", bird_y, bird_vy);

        // another tick
        do_tick();
        $display("After post-flap tick: y=%0d vy=%0d", bird_y, bird_vy);

        $finish;
    end
endmodule