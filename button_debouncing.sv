`default_nettype none

module button_sync_onepulse (
    input  logic clk,
    input  logic reset,
    input  logic btn_in,
    output logic btn_pulse
);
    logic sync0, sync1, sync1_d;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sync0    <= 1'b0;
            sync1    <= 1'b0;
            sync1_d  <= 1'b0;
        end else begin
            sync0    <= btn_in;
            sync1    <= sync0;
            sync1_d  <= sync1;
        end
    end

    assign btn_pulse = sync1 & ~sync1_d;   // rising-edge one pulse
endmodule


module button_sync_onepulse_tb;
    logic clk, reset, btn_in;
    logic btn_pulse;

    button_sync_onepulse dut (
        .clk(clk),
        .reset(reset),
        .btn_in(btn_in),
        .btn_pulse(btn_pulse)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset  = 1;
        btn_in = 0;
        repeat (2) @(posedge clk);
        reset = 0;

        // Press and hold button
        @(posedge clk) btn_in = 1;
        repeat (5) @(posedge clk);
        btn_in = 0;

        // Press again
        repeat (3) @(posedge clk);
        btn_in = 1;
        repeat (3) @(posedge clk);
        btn_in = 0;

        repeat (5) @(posedge clk);
        $finish;
    end

    int pulse_count = 0;
    always @(posedge clk) begin
        if (btn_pulse)
            pulse_count++;

        $display("t=%0t btn_in=%0b btn_pulse=%0b pulse_count=%0d",
                 $time, btn_in, btn_pulse, pulse_count);
    end

    final begin
        if (pulse_count != 2)
            $error("Expected 2 pulses, got %0d", pulse_count);
        else
            $display("button_sync_onepulse_tb PASSED");
    end
endmodule