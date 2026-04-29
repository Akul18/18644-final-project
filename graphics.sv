module renderer #(
    parameter int SCREEN_W   = 640,
    parameter int SCREEN_H   = 480,
    parameter int BIRD_X     = 120,
    parameter int BIRD_W     = 24,
    parameter int BIRD_H     = 24,
    parameter int PIPE_WIDTH = 60,
    parameter int GAP_HEIGHT = 120,
    parameter int GROUND_Y   = 430
) (
    input  logic [9:0] row,
    input  logic [9:0] col,
    input  logic       blank,
    input  logic       game_active,

    input  logic signed [10:0] bird_y,
    input  logic signed [10:0] bird_vy,   

    input  logic [10:0] pipe0_x, pipe1_x, pipe2_x,
    input  logic [9:0]  gap0_y,  gap1_y,  gap2_y,

    output logic [2:0] r,
    output logic [2:0] g,
    output logic [2:0] b
);
    logic ground_on;
    logic pipe0_on, pipe1_on, pipe2_on;

    logic signed [10:0] brow, bcol;  

    // Bird layers
    logic body_on, eye_on, pupil_on, beak_on, wing_on;
    logic bird_on;


    function automatic logic pipe_pixel_on(
        input logic [10:0] col_in,
        input logic [9:0]  row_in,
        input logic [10:0] pipe_x,
        input logic [9:0]  gap_y
    );
        pipe_pixel_on =
            (col_in >= pipe_x) &&
            (col_in <  pipe_x + 11'(PIPE_WIDTH)) &&
            ((row_in < gap_y) || (row_in >= gap_y + GAP_HEIGHT));
    endfunction

    // ----------------------------------------------------------------
    // Bird shape — all coordinates are offsets from (BIRD_X, bird_y)
    // The bird is 24x24. Centre of body circle is at (12, 12).
    //
    //   body:   filled circle r=10 centred at (12,12)
    //   eye:    filled circle r=3  centred at (17, 8)  (upper right)
    //   pupil:  filled circle r=1  centred at (18, 8)
    //   beak:   triangle-ish block cols 21-23, rows 10-13
    //   wing:   small ellipse that shifts up when vy < 0 (flapping)
    //           centred at (8, 16+wing_offset)
    // ----------------------------------------------------------------
    logic signed [10:0] wing_offset;

    always_comb begin
        if (bird_vy < -2)
            wing_offset = -3;          
        else if (bird_vy > 3)
            wing_offset = 3;          
        else
            wing_offset = 0;

        brow = $signed({1'b0, row}) - bird_y;
        bcol = $signed({1'b0, col}) - $signed(11'(BIRD_X));

        if (brow >= 0 && brow < BIRD_H && bcol >= 0 && bcol < BIRD_W) begin

            // Body: circle centred at (12,12) radius 10
            // (bcol-12)^2 + (brow-12)^2 <= 100
            body_on = ( (bcol-11'sd12)*(bcol-11'sd12) +
                        (brow-11'sd12)*(brow-11'sd12) ) <= 11'sd100;

            // Eye white: circle centred at (17,8) radius 3
            eye_on  = ( (bcol-11'sd17)*(bcol-11'sd17) +
                        (brow-11'sd8) *(brow-11'sd8)  ) <= 11'sd9;

            // Pupil: circle centred at (18,8) radius 1
            pupil_on = ( (bcol-11'sd18)*(bcol-11'sd18) +
                         (brow-11'sd8) *(brow-11'sd8)  ) <= 11'sd1;

            // Beak: small rectangle on the right side
            beak_on = (bcol >= 11'sd20) && (bcol <= 11'sd23) &&
                      (brow >= 11'sd10) && (brow <= 11'sd13);

            // Wing: small ellipse, shifts with velocity
            // Ellipse: (bcol-8)^2/9 + (brow-16-offset)^2/4 <= 1
            // Multiply through by 36: 4*(bcol-8)^2 + 9*(brow-16-offset)^2 <= 36
            wing_on = ( 4*(bcol-11'sd8)*(bcol-11'sd8) +
                        9*(brow-11'sd16-wing_offset)*(brow-11'sd16-wing_offset)
                      ) <= 11'sd36;

            bird_on = body_on || eye_on || wing_on || beak_on;

        end else begin
            body_on  = 1'b0;
            eye_on   = 1'b0;
            pupil_on = 1'b0;
            beak_on  = 1'b0;
            wing_on  = 1'b0;
            bird_on  = 1'b0;
        end

        ground_on = (row >= GROUND_Y);

        pipe0_on = game_active && pipe_pixel_on(11'(col), row, pipe0_x, gap0_y);
        pipe1_on = game_active && pipe_pixel_on(11'(col), row, pipe1_x, gap1_y);
        pipe2_on = game_active && pipe_pixel_on(11'(col), row, pipe2_x, gap2_y);


        if (blank) begin
            r = 3'b000; g = 3'b000; b = 3'b000;

        end else if (ground_on) begin
            r = 3'b101; g = 3'b100; b = 3'b000;   // brown ground

        end else if (beak_on) begin
            r = 3'b111; g = 3'b101; b = 3'b000;   // orange beak

        end else if (pupil_on) begin
            r = 3'b000; g = 3'b000; b = 3'b000;   // black pupil

        end else if (eye_on) begin
            r = 3'b111; g = 3'b111; b = 3'b111;   // white eye

        end else if (body_on || wing_on) begin
            r = 3'b111; g = 3'b110; b = 3'b000;   // yellow body/wing

        end else if (pipe0_on || pipe1_on || pipe2_on) begin
            r = 3'b000; g = 3'b111; b = 3'b000;   // green pipe

        end else begin
            r = 3'b010; g = 3'b110; b = 3'b111;   // sky
        end
    end
endmodule