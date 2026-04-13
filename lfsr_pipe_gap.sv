`default_nettype none


module lfsr16 (
    input  logic       clk,
    input  logic       reset,
    input  logic       en,
    output logic [15:0] rnd
);
    logic feedback;

    assign feedback = rnd[15] ^ rnd[13] ^ rnd[12] ^ rnd[10];

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            rnd <= 16'hACE1;   // nonzero seed
        else if (en)
            rnd <= {rnd[14:0], feedback};
    end
endmodule

module lfsr16_tb;
    logic clk, reset, en;
    logic [15:0] rnd;

    lfsr16 dut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .rnd(rnd)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    logic [15:0] prev_rnd;

    initial begin
        reset = 1;
        en    = 0;
        repeat (2) @(posedge clk);
        reset = 0;

        // Hold disabled
        prev_rnd = rnd;
        repeat (3) @(posedge clk);
        if (rnd !== prev_rnd)
            $error("LFSR changed while en=0");

        // Enable and watch change
        en = 1;
        repeat (10) begin
            @(posedge clk);
            $display("t=%0t rnd=%h", $time, rnd);
        end

        // Disable again
        en = 0;
        prev_rnd = rnd;
        repeat (3) @(posedge clk);
        if (rnd !== prev_rnd)
            $error("LFSR changed while en=0 after running");

        $display("lfsr16_tb PASSED");
        $finish;
    end
endmodule