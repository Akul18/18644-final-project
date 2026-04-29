module bird_physics #(
    parameter int SCREEN_H      = 480,
    parameter int GROUND_Y      = 430,
    parameter int BIRD_START_Y  = 200,
    parameter int GRAVITY       = 8,
    parameter int JUMP_IMPULSE  = -80
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        tick,        
    input  logic        game_active,
    input  logic        flap_pulse, 
    output logic signed [10:0] bird_y,
    output logic signed [10:0] bird_vy
);
    logic signed [14:0] y_full, vy_full;
    logic               flap_pending;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            flap_pending <= 1'b0;
        end else if (!game_active) begin
            flap_pending <= 1'b0;
        end else begin
            if (flap_pulse)
                flap_pending <= 1'b1;
            else if (tick)
                flap_pending <= 1'b0;
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            y_full  <= (BIRD_START_Y << 4); 
            vy_full <= 0;
        end else if (!game_active) begin
            y_full  <= (BIRD_START_Y << 4);
            vy_full <= 0;
        end else if (tick) begin
            // Apply Jump or Gravity
            if (flap_pending || flap_pulse) begin
                vy_full <= JUMP_IMPULSE;
            end else begin
                vy_full <= vy_full + GRAVITY;
            end

            y_full <= y_full + vy_full;
        end
    end


    assign bird_y  = y_full[14:4];
    assign bird_vy = vy_full[14:4];

endmodule
