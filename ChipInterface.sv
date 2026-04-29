module ChipInterface (
    input  logic btn_left,
    input  logic btn_right,
    input  logic btn_up,
    input  logic btn_down,
    input  logic clock,
    input  logic reset_n,

    output logic vga_r0,
    output logic vga_r1,
    output logic vga_g0,
    output logic vga_g1,
    output logic vga_b0,
    output logic vga_b1,
    output logic vga_hs,
    output logic vga_vs
);

    logic blank;
    logic [2:0] r, g, b;

    flappy_top flappy (
        .CLOCK_50  (clock),
        .reset     (~reset_n),
        .btn_start (btn_left),
        .btn_jump  (btn_up),

        .HS        (vga_hs),
        .VS        (vga_vs),
        .blank     (blank),
        .r         (r),
        .g         (g),
        .b         (b)
    );

    assign vga_r0 = r[1];
    assign vga_r1 = r[2];
    assign vga_g0 = g[1];
    assign vga_g1 = g[2];
    assign vga_b0 = b[1];
    assign vga_b1 = b[2];

endmodule : ChipInterface