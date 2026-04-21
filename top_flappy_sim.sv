`default_nettype none
`timescale 1ns / 1ps

module top_flappy_sim #(parameter CORDW=10) (
    input  logic clk_pix,
    input  logic sim_rst,
    input  logic btn_start,
    input  logic btn_jump,

    output logic [CORDW-1:0] sdl_sx,
    output logic [CORDW-1:0] sdl_sy,
    output logic             sdl_de,
    output logic [7:0]       sdl_r,
    output logic [7:0]       sdl_g,
    output logic [7:0]       sdl_b
);

    // VGA timing
    logic [9:0] row, col;
    logic HS, VS, blank;

    vga vga_inst (
        .row      (row),
        .col      (col),
        .HS       (HS),
        .VS       (VS),
        .blank    (blank),
        .CLOCK_50 (clk_pix),
        .reset    (sim_rst)
    );

    // Game timing
    logic tick;
    assign tick = (row == 10'd0 && col == 10'd0);

    // logic tick;
    // localparam int SIM_DIV = 833333;

    // game_tick #(.DIV(SIM_DIV)) tick_gen (
    //     .clk   (clk_pix),
    //     .reset (sim_rst),
    //     .tick  (tick)
    // );

    // Button handling
    logic start_pulse, jump_pulse;
    logic start_pending, jump_pending;

    button_sync_onepulse start_btn_sync (
        .clk       (clk_pix),
        .reset     (sim_rst),
        .btn_in    (btn_start),
        .btn_pulse (start_pulse)
    );

    button_sync_onepulse jump_btn_sync (
        .clk       (clk_pix),
        .reset     (sim_rst),
        .btn_in    (btn_jump),
        .btn_pulse (jump_pulse)
    );

    always_ff @(posedge clk_pix or posedge sim_rst) begin
        if (sim_rst) begin
            start_pending <= 1'b0;
            jump_pending  <= 1'b0;
        end else begin
            if (start_pulse)
                start_pending <= 1'b1;
            else if (tick)
                start_pending <= 1'b0;

            if (jump_pulse)
                jump_pending <= 1'b1;
            else if (tick)
                jump_pending <= 1'b0;
        end
    end

    // Randomness
    logic [15:0] rnd;

    lfsr16 rand_gen (
        .clk   (clk_pix),
        .reset (sim_rst),
        .en    (tick),
        .rnd   (rnd)
    );

    // Game state
    logic signed [10:0] bird_y, bird_vy;

    logic [9:0] pipe0_x, pipe1_x, pipe2_x;
    logic [9:0] gap0_y,  gap1_y,  gap2_y;
    logic wrap0, wrap1, wrap2;

    logic hit0, hit1, hit2;
    logic collision;

    logic passed0, passed1, passed2;
    logic [7:0] score;

    logic game_active, clear_game;
    logic [1:0] state;

    game_fsm fsm (
        .clk         (clk_pix),
        .reset       (sim_rst),
        .tick        (tick),
        .start_pulse (start_pending),
        .collision   (collision),
        .game_active (game_active),
        .clear_game  (clear_game),
        .state       (state)
    );

    bird_physics bird (
        .clk         (clk_pix),
        .reset       (sim_rst),
        .tick        (tick),
        .game_active (game_active),
        .flap_pulse  (jump_pending && game_active),
        .bird_y      (bird_y),
        .bird_vy     (bird_vy)
    );

    pipe_unit pipe0 (
        .clk         (clk_pix),
        .reset       (sim_rst),
        .tick        (tick),
        .game_active (game_active),
        .rnd         (rnd),
        .spawn_x     (10'd640),
        .pipe_x      (pipe0_x),
        .gap_y       (gap0_y),
        .wrapped     (wrap0)
    );

    pipe_unit pipe1 (
        .clk         (clk_pix),
        .reset       (sim_rst),
        .tick        (tick),
        .game_active (game_active),
        .rnd         ({rnd[7:0], rnd[15:8]}),
        .spawn_x     (10'd820),
        .pipe_x      (pipe1_x),
        .gap_y       (gap1_y),
        .wrapped     (wrap1)
    );

    pipe_unit pipe2 (
        .clk         (clk_pix),
        .reset       (sim_rst),
        .tick        (tick),
        .game_active (game_active),
        .rnd         (rnd ^ 16'hBEEF),
        .spawn_x     (10'd1000),
        .pipe_x      (pipe2_x),
        .gap_y       (gap2_y),
        .wrapped     (wrap2)
    );

    collision_unit col0 (
        .bird_y      (bird_y),
        .pipe_x      (pipe0_x),
        .gap_y       (gap0_y),
        .hit_pipe    (),
        .hit_floor   (),
        .hit_ceiling (),
        .collision   (hit0)
    );

    collision_unit col1 (
        .bird_y      (bird_y),
        .pipe_x      (pipe1_x),
        .gap_y       (gap1_y),
        .hit_pipe    (),
        .hit_floor   (),
        .hit_ceiling (),
        .collision   (hit1)
    );

    collision_unit col2 (
        .bird_y      (bird_y),
        .pipe_x      (pipe2_x),
        .gap_y       (gap2_y),
        .hit_pipe    (),
        .hit_floor   (),
        .hit_ceiling (),
        .collision   (hit2)
    );

    assign collision = hit0 | hit1 | hit2;

    score_unit s0 (
        .clk          (clk_pix),
        .reset        (sim_rst),
        .tick         (tick),
        .game_active  (game_active),
        .pipe_x       (pipe0_x),
        .pipe_wrapped (wrap0),
        .passed_pulse (passed0)
    );

    score_unit s1 (
        .clk          (clk_pix),
        .reset        (sim_rst),
        .tick         (tick),
        .game_active  (game_active),
        .pipe_x       (pipe1_x),
        .pipe_wrapped (wrap1),
        .passed_pulse (passed1)
    );

    score_unit s2 (
        .clk          (clk_pix),
        .reset        (sim_rst),
        .tick         (tick),
        .game_active  (game_active),
        .pipe_x       (pipe2_x),
        .pipe_wrapped (wrap2),
        .passed_pulse (passed2)
    );

    score_counter score_ctr (
        .clk         (clk_pix),
        .reset       (sim_rst),
        .clear_score (clear_game),
        .inc_score   (passed0 | passed1 | passed2),
        .score       (score)
    );

    // Rendering
    logic [2:0] r, g, b;

    renderer draw (
        .row     (row),
        .col     (col),
        .blank   (blank),
        .bird_y  (bird_y),
        .pipe0_x (pipe0_x),
        .pipe1_x (pipe1_x),
        .pipe2_x (pipe2_x),
        .gap0_y  (gap0_y),
        .gap1_y  (gap1_y),
        .gap2_y  (gap2_y),
        .r       (r),
        .g       (g),
        .b       (b)
    );

    // SDL outputs
    always_ff @(posedge clk_pix or posedge sim_rst) begin
        if (sim_rst) begin
            sdl_sx <= '0;
            sdl_sy <= '0;
            sdl_de <= 1'b0;
            sdl_r  <= 8'd0;
            sdl_g  <= 8'd0;
            sdl_b  <= 8'd0;
        end else begin
            sdl_sx <= col;
            sdl_sy <= row;
            sdl_de <= ~blank;

            // expand 3-bit RGB to 8-bit
            sdl_r <= {r, r, 2'b00};
            sdl_g <= {g, g, 2'b00};
            sdl_b <= {b, b, 2'b00};
        end
    end

endmodule