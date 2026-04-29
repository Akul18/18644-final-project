module score_unit #(
    parameter int BIRD_X     = 120,
    parameter int PIPE_WIDTH = 60
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        tick,
    input  logic        game_active,
    input  logic [10:0] pipe_x,       // widened to 11-bit to match pipe_unit
    input  logic        pipe_wrapped,
    output logic        passed_pulse
);
    logic scored_this_pipe;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            scored_this_pipe <= 1'b0;
            passed_pulse     <= 1'b0;
        end else if (!game_active) begin
            scored_this_pipe <= 1'b0;
            passed_pulse     <= 1'b0;
        end else if (tick) begin
            passed_pulse <= 1'b0;

            if (pipe_wrapped)
                scored_this_pipe <= 1'b0;

            if (!scored_this_pipe &&
                (pipe_x < 11'(640)) &&
                (pipe_x + 11'(PIPE_WIDTH) < 11'(BIRD_X))) begin
                scored_this_pipe <= 1'b1;
                passed_pulse     <= 1'b1;
            end
        end else begin
            passed_pulse <= 1'b0;
        end
    end
endmodule

module score_counter (
    input  logic       clk,
    input  logic       reset,
    input  logic       clear_score,
    input  logic       inc_score,
    output logic [7:0] score
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            score <= 8'd0;
        else if (clear_score)
            score <= 8'd0;
        else if (inc_score && score != 8'hFF)  
            score <= score + 8'd1;
    end
endmodule
