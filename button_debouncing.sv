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
