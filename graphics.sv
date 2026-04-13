module renderer #(
    parameter int SCREEN_W    = 640,
    parameter int SCREEN_H    = 480,
    parameter int BIRD_X      = 120,
    parameter int BIRD_W      = 24,
    parameter int BIRD_H      = 24,
    parameter int PIPE_WIDTH  = 60,
    parameter int GAP_HEIGHT  = 120,
    parameter int GROUND_Y    = 430
) (
    input  logic [9:0] row,
    input  logic [9:0] col,
    input  logic       blank,

    input  logic signed [10:0] bird_y,
    input  logic [9:0] pipe0_x, pipe1_x, pipe2_x,
    input  logic [9:0] gap0_y,  gap1_y,  gap2_y,

    output logic [2:0] r,
    output logic [2:0] g,
    output logic [2:0] b
);
    logic bird_on, ground_on;
    logic pipe0_on, pipe1_on, pipe2_on;

    function automatic logic pipe_pixel_on(
        input logic [9:0] x,
        input logic [9:0] y,
        input logic [9:0] pipe_x,
        input logic [9:0] gap_y
    );
        begin
            pipe_pixel_on =
                (x >= pipe_x) && (x < pipe_x + PIPE_WIDTH) &&
                ( (y < gap_y) || (y >= gap_y + GAP_HEIGHT) );
        end
    endfunction

    always_comb begin
        bird_on   = (col >= BIRD_X) && (col < BIRD_X + BIRD_W) &&
                    (row >= bird_y) && (row < bird_y + BIRD_H);

        ground_on = (row >= GROUND_Y);

        pipe0_on  = pipe_pixel_on(col, row, pipe0_x, gap0_y);
        pipe1_on  = pipe_pixel_on(col, row, pipe1_x, gap1_y);
        pipe2_on  = pipe_pixel_on(col, row, pipe2_x, gap2_y);

        if (blank) begin
            r = 3'b000; g = 3'b000; b = 3'b000;
        end else if (ground_on) begin
            r = 3'b101; g = 3'b100; b = 3'b000;
        end else if (bird_on) begin
            r = 3'b111; g = 3'b111; b = 3'b000;
        end else if (pipe0_on || pipe1_on || pipe2_on) begin
            r = 3'b000; g = 3'b111; b = 3'b000;
        end else begin
            r = 3'b010; g = 3'b110; b = 3'b111; // sky
        end
    end
endmodule


module renderer_tb;
    logic [9:0] row, col;
    logic blank;
    logic signed [10:0] bird_y;
    logic [9:0] pipe0_x, pipe1_x, pipe2_x;
    logic [9:0] gap0_y, gap1_y, gap2_y;
    logic [2:0] r, g, b;

    renderer dut (
        .row(row),
        .col(col),
        .blank(blank),
        .bird_y(bird_y),
        .pipe0_x(pipe0_x), .pipe1_x(pipe1_x), .pipe2_x(pipe2_x),
        .gap0_y(gap0_y),   .gap1_y(gap1_y),   .gap2_y(gap2_y),
        .r(r), .g(g), .b(b)
    );

    initial begin
        bird_y  = 200;
        pipe0_x = 300; gap0_y = 150;
        pipe1_x = 500; gap1_y = 180;
        pipe2_x = 700; gap2_y = 220;

        // blank pixel
        blank = 1; row = 10; col = 10; #1;
        if ({r,g,b} !== 9'b0) $error("Expected black during blank");

        // bird pixel
        blank = 0; row = 205; col = 125; #1;
        $display("Bird pixel color = %b %b %b", r, g, b);

        // ground pixel
        row = 450; col = 50; #1;
        $display("Ground pixel color = %b %b %b", r, g, b);

        // sky pixel
        row = 50; col = 50; #1;
        $display("Sky pixel color = %b %b %b", r, g, b);

        // pipe pixel
        row = 100; col = 310; #1; // inside top pipe0
        $display("Pipe pixel color = %b %b %b", r, g, b);

        $display("renderer_tb done");
        $finish;
    end
endmodule