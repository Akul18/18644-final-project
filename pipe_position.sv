module pipe_unit #(
    parameter int PIPE_SPEED = 4,
    parameter int PIPE_WIDTH = 60,
    parameter int GAP_MIN    = 80,
    parameter int GAP_RANGE  = 220
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        tick,
    input  logic        game_active,
    input  logic [15:0] rnd,
    input  logic [10:0] init_x,
    input  logic [10:0] spawn_x,
    output logic [10:0] pipe_x,
    output logic [9:0]  gap_y,
    output logic        wrapped
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pipe_x  <= init_x;
            gap_y   <= 10'd200;
            wrapped <= 1'b0;
        end else if (!game_active) begin
            pipe_x  <= init_x;
            gap_y   <= 10'd200;
            wrapped <= 1'b0;
        end else if (tick) begin
            wrapped <= 1'b0;
            if (pipe_x < 11'(PIPE_SPEED + PIPE_WIDTH)) begin
                pipe_x  <= spawn_x;
                gap_y   <= GAP_MIN + rnd[7:0];
                wrapped <= 1'b1;
            end else begin
                pipe_x <= pipe_x - 11'(PIPE_SPEED);
            end
        end else begin
            wrapped <= 1'b0;
        end
    end
endmodule