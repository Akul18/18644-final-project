module vga (
    output logic [9:0] row, col,
    output logic       HS, VS, blank,
    input  logic       CLOCK_50, reset
);

    logic [9:0] col_count;
    logic [9:0] row_count;

    simple_counter #(10) col_counter (
        .Q     (col_count),
        .en    (1'b1),
        .clr   (col_count >= 10'd799),
        .clk   (CLOCK_50),
        .reset (reset)
    );

    simple_counter #(10) row_counter (
        .Q     (row_count),
        .en    (col_count == 10'd799),
        .clr   ((row_count >= 10'd524) && (col_count == 10'd799)),
        .clk   (CLOCK_50),
        .reset (reset)
    );

    assign col = col_count;
    assign row = row_count;

    // 640x480 @ ~60 Hz VGA timing
    // visible: 0-639
    // front porch: 640-655
    // sync pulse: 656-751
    // back porch: 752-799
    assign HS = ~((col_count >= 10'd656) && (col_count <= 10'd751));

    // visible: 0-479
    // front porch: 480-489
    // sync pulse: 490-491
    // back porch: 492-524
    assign VS = ~((row_count >= 10'd490) && (row_count <= 10'd491));

    assign blank = (col_count >= 10'd640) || (row_count >= 10'd480);

endmodule : vga

module simple_counter
    #(parameter WIDTH = 4'd8) (
    output logic [WIDTH-1:0] Q,
    input  logic             clk, en, clr, reset
    );

    always_ff @(posedge clk, posedge reset)
        if (reset)
            Q <= 'b0;
        else if (clr)
            Q <= 'b0;
        else if (en)
            Q <= (Q + 1'b1);

endmodule: simple_counter