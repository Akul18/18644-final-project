module collision_unit #(
    parameter int BIRD_X      = 120,
    parameter int BIRD_W      = 24,
    parameter int BIRD_H      = 24,
    parameter int PIPE_WIDTH  = 60,
    parameter int GAP_HEIGHT  = 120,
    parameter int GROUND_Y    = 430
) (
    input  logic signed [10:0] bird_y,
    input  logic [9:0]         pipe_x,
    input  logic [9:0]         gap_y,
    output logic               hit_pipe,
    output logic               hit_floor,
    output logic               hit_ceiling,
    output logic               collision
);
    logic [10:0] bird_top, bird_bottom;
    logic [9:0]  bird_left, bird_right;
    logic [9:0]  pipe_left, pipe_right;
    logic        x_overlap;
    logic        hit_top_pipe, hit_bottom_pipe;

    always_comb begin
        bird_top    = bird_y;
        bird_bottom = bird_y + BIRD_H;
        bird_left   = BIRD_X;
        bird_right  = BIRD_X + BIRD_W;

        pipe_left   = pipe_x;
        pipe_right  = pipe_x + PIPE_WIDTH;

        hit_ceiling = (bird_top <= 0);
        hit_floor   = (bird_bottom >= GROUND_Y);

        x_overlap   = (bird_right >= pipe_left) && (bird_left <= pipe_right);

        hit_top_pipe    = x_overlap && (bird_top <= gap_y);
        hit_bottom_pipe = x_overlap && (bird_bottom >= (gap_y + GAP_HEIGHT));

        hit_pipe    = hit_top_pipe || hit_bottom_pipe;
        collision   = hit_ceiling || hit_floor || hit_pipe;
    end
endmodule



module collision_unit_tb;
    logic signed [10:0] bird_y;
    logic [9:0] pipe_x, gap_y;
    logic hit_pipe, hit_floor, hit_ceiling, collision;

    collision_unit #(
        .BIRD_X(120),
        .BIRD_W(24),
        .BIRD_H(24),
        .PIPE_WIDTH(60),
        .GAP_HEIGHT(120),
        .GROUND_Y(430)
    ) dut (
        .bird_y(bird_y),
        .pipe_x(pipe_x),
        .gap_y(gap_y),
        .hit_pipe(hit_pipe),
        .hit_floor(hit_floor),
        .hit_ceiling(hit_ceiling),
        .collision(collision)
    );

    initial begin
        // Safe
        bird_y = 150;
        pipe_x = 300;
        gap_y  = 100;
        #1;
        if (collision) $error("Unexpected collision in safe test");

        // Pipe x-overlap, bird hits top pipe
        pipe_x = 120;
        gap_y  = 200;
        bird_y = 150;  // above gap
        #1;
        if (!hit_pipe) $error("Expected top pipe hit");

        // Pipe x-overlap, bird hits bottom pipe
        bird_y = 340;  // below gap
        #1;
        if (!hit_pipe) $error("Expected bottom pipe hit");

        // In gap, no hit
        bird_y = 220;
        #1;
        if (hit_pipe) $error("Unexpected pipe hit while in gap");

        // Floor
        bird_y = 420;
        #1;
        if (!hit_floor) $error("Expected floor hit");

        $display("collision_unit_tb PASSED");
        $finish;
    end
endmodule