module pipe_unit #(
    parameter int SCREEN_W    = 640,
    parameter int PIPE_WIDTH  = 60,
    parameter int PIPE_START_X = 640,
    parameter int PIPE_SPACING = 220,
    parameter int PIPE_SPEED   = 4,
    parameter int GAP_MIN      = 80,
    parameter int GAP_RANGE    = 220
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        tick,
    input  logic        game_active,
    input  logic [15:0] rnd,
    input  logic [9:0]  spawn_x,
    output logic [9:0]  pipe_x,
    output logic [9:0]  gap_y,
    output logic        wrapped
);
    logic [9:0] next_gap_y;

    assign next_gap_y = GAP_MIN + rnd[7:0];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pipe_x   <= spawn_x;
            gap_y    <= 10'd200;
            wrapped  <= 1'b0;
        end else if (!game_active) begin
            pipe_x   <= spawn_x;
            gap_y    <= 10'd200;
            wrapped  <= 1'b0;
        end else if (tick) begin
            wrapped <= 1'b0;
            if (pipe_x <= PIPE_SPEED) begin
                pipe_x  <= spawn_x;
                gap_y   <= next_gap_y;
                wrapped <= 1'b1;
            end else begin
                pipe_x  <= pipe_x - PIPE_SPEED;
            end
        end else begin
            wrapped <= 1'b0;
        end
    end
endmodule

module pipe_unit_tb;
    logic clk, reset, tick, game_active;
    logic [15:0] rnd;
    logic [9:0] spawn_x;
    logic [9:0] pipe_x, gap_y;
    logic wrapped;

    pipe_unit #(
        .PIPE_SPEED(4),
        .GAP_MIN(80)
    ) dut (
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .game_active(game_active),
        .rnd(rnd),
        .spawn_x(spawn_x),
        .pipe_x(pipe_x),
        .gap_y(gap_y),
        .wrapped(wrapped)
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
        rnd = 16'h0034;
        spawn_x = 10'd20;   // small for quick wrap in sim
        repeat (2) @(posedge clk);
        reset = 0;

        if (pipe_x !== spawn_x)
            $error("Pipe did not reset to spawn_x");

        game_active = 1;

        do_tick(); // 20 -> 16
        do_tick(); // 16 -> 12
        do_tick(); // 12 -> 8
        do_tick(); // 8 -> 4
        do_tick(); // 4 -> wrap

        $display("After wrap: pipe_x=%0d gap_y=%0d wrapped=%0b", pipe_x, gap_y, wrapped);

        if (pipe_x !== spawn_x)
            $error("Pipe did not wrap to spawn_x");

        $finish;
    end
endmodule