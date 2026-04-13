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

module game_tick_tb;
    logic clk, reset, tick;

    game_tick #(.DIV(5)) dut (
        .clk(clk),
        .reset(reset),
        .tick(tick)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    int cyc_since_tick;

    initial begin
        reset = 1;
        cyc_since_tick = 0;
        repeat (2) @(posedge clk);
        reset = 0;

        repeat (25) @(posedge clk);
        $finish;
    end

    always @(posedge clk) begin
        if (reset) begin
            cyc_since_tick <= 0;
        end else begin
            if (tick) begin
                $display("tick at t=%0t", $time);
                cyc_since_tick <= 1;
            end else begin
                cyc_since_tick <= cyc_since_tick + 1;
            end
        end
    end
endmodule