module collision_unit #(
    parameter int BIRD_X     = 120,
    parameter int BIRD_W     = 24,
    parameter int BIRD_H     = 24,
    parameter int PIPE_WIDTH = 60,
    parameter int GAP_HEIGHT = 120,
    parameter int GROUND_Y   = 430
) (
    input  logic signed [10:0] bird_y,
    input  logic        [10:0] pipe_x,
    input  logic        [9:0]  gap_y,
    output logic               hit_pipe,
    output logic               hit_floor,
    output logic               hit_ceiling,
    output logic               collision
);
    logic signed [10:0] bird_top, bird_bottom;
    logic        [10:0] bird_left, bird_right;
    logic        [10:0] pipe_left, pipe_right;
    logic               x_overlap;
    logic               hit_top_pipe, hit_bottom_pipe;

    always_comb begin
        bird_top    = bird_y;
        bird_bottom = bird_y + 11'(BIRD_H);
        bird_left   = 11'(BIRD_X);
        bird_right  = 11'(BIRD_X + BIRD_W);

        pipe_left   = pipe_x;
        pipe_right  = pipe_x + 11'(PIPE_WIDTH);

        hit_ceiling = (bird_top  <= 11'sd0);
        hit_floor   = (bird_bottom >= 11'(GROUND_Y));

        x_overlap = (pipe_x < 11'(640)) &&
                    (bird_right >= pipe_left) &&
                    (bird_left  <= pipe_right);

        hit_top_pipe    = x_overlap && (bird_top    <= 11'(gap_y));
        hit_bottom_pipe = x_overlap && (bird_bottom >= 11'(gap_y + GAP_HEIGHT));

        hit_pipe  = hit_top_pipe || hit_bottom_pipe;
        collision = hit_ceiling || hit_floor || hit_pipe;
    end
endmodule