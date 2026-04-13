module score_unit #(
    parameter int BIRD_X     = 120,
    parameter int PIPE_WIDTH = 60
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       tick,
    input  logic       game_active,
    input  logic [9:0] pipe_x,
    input  logic       pipe_wrapped,
    output logic       passed_pulse
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

            if (!scored_this_pipe && (pipe_x + PIPE_WIDTH < BIRD_X)) begin
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
        else if (inc_score)
            score <= score + 1'b1;
    end
endmodule

module score_unit_tb;
    logic clk, reset, tick, game_active;
    logic [9:0] pipe_x;
    logic pipe_wrapped;
    logic passed_pulse;

    score_unit #(
        .BIRD_X(120),
        .PIPE_WIDTH(60)
    ) dut (
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .game_active(game_active),
        .pipe_x(pipe_x),
        .pipe_wrapped(pipe_wrapped),
        .passed_pulse(passed_pulse)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task tick_once;
        begin
            tick = 1;
            @(posedge clk);
            #1;
            tick = 0;
        end
    endtask

    task idle_cycle;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    int pulse_count = 0;

    always @(posedge clk) begin
        if (passed_pulse) begin
            pulse_count++;
            $display("passed_pulse at t=%0t", $time);
        end
    end

    initial begin
        reset = 1;
        tick = 0;
        game_active = 0;
        pipe_x = 200;
        pipe_wrapped = 0;

        repeat (2) @(posedge clk);
        #1;
        reset = 0;

        game_active = 1;

        // Not yet passed
        pipe_x = 100;
        tick_once();
        if (passed_pulse) $error("Scored too early");
        idle_cycle();

        // Passes bird
        pipe_x = 50;
        tick_once();
        if (!passed_pulse) $error("Expected passed_pulse");
        idle_cycle();

        // Should not score again
        tick_once();
        if (passed_pulse) $error("Should not score again");
        idle_cycle();

        tick_once();
        if (passed_pulse) $error("Should not score again");
        idle_cycle();

        // Wrap resets scored flag
        pipe_wrapped = 1;
        tick_once();
        pipe_wrapped = 0;
        idle_cycle();

        // Pass again after wrap
        pipe_x = 50;
        tick_once();
        if (!passed_pulse) $error("Expected second passed_pulse");
        idle_cycle();

        if (pulse_count != 2)
            $error("Expected 2 score pulses, got %0d", pulse_count);

        $display("score_unit_tb PASSED");
        $finish;
    end
endmodule