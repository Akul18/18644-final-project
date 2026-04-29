module game_tick #(
    parameter integer DIV = 833333  // ~60 Hz from 50 MHz
) (
    input  logic clk,
    input  logic reset,
    output logic tick
);
    localparam W = $clog2(DIV);
    logic [W-1:0] count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= '0;
            tick  <= 1'b0;
        end else if (count == DIV-1) begin
            count <= '0;
            tick  <= 1'b1;
        end else begin
            count <= count + 1'b1;
            tick  <= 1'b0;
        end
    end
endmodule
